-- Add phone field to user_profiles table
ALTER TABLE public.user_profiles 
ADD COLUMN phone text;

-- Add comment to document the field
COMMENT ON COLUMN public.user_profiles.phone IS 'User phone number';