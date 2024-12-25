/*
  # Initial Schema Setup for Anonymous Messaging App

  1. New Tables
    - profiles: Stores user profile information
    - messages: Stores anonymous messages
    - user_status: Tracks user online status and last seen

  2. Security
    - Enable RLS on all tables
    - Add appropriate policies for each table
*/

-- Create profiles table
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  username TEXT NOT NULL UNIQUE,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create messages table
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id UUID NOT NULL REFERENCES profiles(id),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create user_status table
CREATE TABLE user_status (
  user_id UUID PRIMARY KEY REFERENCES profiles(id),
  is_online BOOLEAN DEFAULT false,
  last_seen TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_status ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles
  FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles
  FOR UPDATE
  USING (auth.uid() = id);

-- Messages policies
CREATE POLICY "Users can view messages sent to them"
  ON messages
  FOR SELECT
  USING (auth.uid() = recipient_id);

CREATE POLICY "Anyone can send messages"
  ON messages
  FOR INSERT
  WITH CHECK (true);

-- User status policies
CREATE POLICY "Status is viewable by everyone"
  ON user_status
  FOR SELECT
  USING (true);

CREATE POLICY "Users can update own status"
  ON user_status
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Create function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, username)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8))
  );

  INSERT INTO user_status (user_id, is_online, last_seen)
  VALUES (NEW.id, false, now());

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();