DO $$
BEGIN
  IF to_regclass('storage.objects') IS NULL THEN
    RAISE NOTICE 'storage.objects is not available; skip storage RLS policies.';
    RETURN;
  END IF;
END $$;
--> statement-breakpoint

DO $$
BEGIN
  IF to_regclass('storage.buckets') IS NULL THEN
    RAISE NOTICE 'storage.buckets is not available; skip bucket config.';
    RETURN;
  END IF;

  INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
  )
  VALUES (
    'generated-bgm',
    'generated-bgm',
    true,
    20971520,
    ARRAY['audio/mpeg', 'audio/wav', 'audio/x-wav']::text[]
  )
  ON CONFLICT (id) DO UPDATE
  SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;
END $$;
--> statement-breakpoint

DROP POLICY IF EXISTS "storage_generated_buckets_public_read" ON storage.objects;
--> statement-breakpoint
DROP POLICY IF EXISTS "storage_generated_buckets_service_insert" ON storage.objects;
--> statement-breakpoint
DROP POLICY IF EXISTS "storage_generated_buckets_service_update" ON storage.objects;
--> statement-breakpoint
DROP POLICY IF EXISTS "storage_generated_buckets_service_delete" ON storage.objects;
--> statement-breakpoint

CREATE POLICY "storage_generated_buckets_public_read"
ON storage.objects
AS PERMISSIVE
FOR SELECT
TO anon, authenticated
USING (bucket_id IN ('generated-images', 'generated-bgm'));
--> statement-breakpoint

CREATE POLICY "storage_generated_buckets_service_insert"
ON storage.objects
AS PERMISSIVE
FOR INSERT
TO service_role
WITH CHECK (bucket_id IN ('generated-images', 'generated-bgm'));
--> statement-breakpoint

CREATE POLICY "storage_generated_buckets_service_update"
ON storage.objects
AS PERMISSIVE
FOR UPDATE
TO service_role
USING (bucket_id IN ('generated-images', 'generated-bgm'))
WITH CHECK (bucket_id IN ('generated-images', 'generated-bgm'));
--> statement-breakpoint

CREATE POLICY "storage_generated_buckets_service_delete"
ON storage.objects
AS PERMISSIVE
FOR DELETE
TO service_role
USING (bucket_id IN ('generated-images', 'generated-bgm'));
