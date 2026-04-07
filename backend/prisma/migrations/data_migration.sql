-- Step 1: Add new values to existing ContentType enum to allow migration
ALTER TYPE "ContentType" ADD VALUE IF NOT EXISTS 'text_post';
ALTER TYPE "ContentType" ADD VALUE IF NOT EXISTS 'image_post';
ALTER TYPE "ContentType" ADD VALUE IF NOT EXISTS 'short_form_video';
ALTER TYPE "ContentType" ADD VALUE IF NOT EXISTS 'long_form_video';
ALTER TYPE "ContentType" ADD VALUE IF NOT EXISTS 'carousel_post';

-- Step 2: migrate existing content_type values to new primitives
-- Note: Prisma capitalizes table names by default, hence "Schedule", not schedules
UPDATE "Schedule" SET content_type = 'image_post' WHERE content_type = 'post';
UPDATE "Schedule" SET content_type = 'long_form_video' WHERE content_type = 'video';

-- Step 3: migrate editor users to creator
UPDATE "User" SET role = 'creator' WHERE role = 'editor';

-- Step 4: Drop old columns manually to prevent Prisma ENUM dependency errors during push
ALTER TABLE "UserChannelAssignment" DROP COLUMN IF EXISTS "role";
ALTER TABLE "Schedule" DROP COLUMN IF EXISTS "status";
ALTER TABLE "Schedule" DROP COLUMN IF EXISTS "status_updated_at";
ALTER TABLE "Schedule" DROP COLUMN IF EXISTS "status_updated_by";

-- Step 5: verify (these should return 0 rows after migration)
SELECT COUNT(*) FROM "Schedule" WHERE content_type::text IN ('post', 'video');
SELECT COUNT(*) FROM "User" WHERE role::text = 'editor';
