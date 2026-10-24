CREATE TABLE "public"."media_asset" (
  "media_asset_id"             uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "uploaded_by_participant_id" uuid                     NOT NULL,
  "storage_provider"           text                     NOT NULL,
  "object_key"                 text                     NOT NULL,
  "sha256_digest"              bytea                    NOT NULL,
  "mime_type"                  text                     NOT NULL,
  "created_at"                 timestamp with time zone NOT NULL DEFAULT transaction_timestamp(),
  CONSTRAINT "chk_media_asset_mime_type_not_blank" CHECK ((btrim(mime_type) <> ''::text)),
  CONSTRAINT "chk_media_asset_object_key_not_blank" CHECK ((btrim(object_key) <> ''::text)),
  CONSTRAINT "chk_media_asset_sha256_digest" CHECK ((octet_length(sha256_digest) = 32)),
  CONSTRAINT "chk_media_asset_storage_provider" CHECK ((storage_provider = 'TENCENT_COS'::text)),
  CONSTRAINT "media_asset_pkey" PRIMARY KEY (media_asset_id),
  CONSTRAINT "uq_media_asset_storage_object" UNIQUE (storage_provider, object_key)
);

ALTER TABLE "public"."media_asset"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."media_asset" FROM "anon", "authenticated";

CREATE TABLE "public"."personal_memory_media" (
  "personal_memory_id" uuid             NOT NULL,
  "cut_position"       smallint         NOT NULL,
  "media_asset_id"     uuid             NOT NULL,
  "focal_x"            double precision,
  "focal_y"            double precision,
  "zoom"               double precision,
  CONSTRAINT "chk_personal_memory_media_cut_position" CHECK (((cut_position >= 1) AND (cut_position <= 4))),
  CONSTRAINT "chk_personal_memory_media_focal_x" CHECK (((focal_x IS NULL) OR ((focal_x >= (0)::double precision) AND (focal_x <= (1)::double precision)))),
  CONSTRAINT "chk_personal_memory_media_focal_y" CHECK (((focal_y IS NULL) OR ((focal_y >= (0)::double precision) AND (focal_y <= (1)::double precision)))),
  CONSTRAINT "chk_personal_memory_media_zoom" CHECK (((zoom IS NULL) OR (zoom > (0)::double precision))),
  CONSTRAINT "pk_personal_memory_media" PRIMARY KEY (personal_memory_id, cut_position),
  CONSTRAINT "uq_personal_memory_media_asset" UNIQUE (personal_memory_id, media_asset_id)
);

ALTER TABLE "public"."personal_memory_media"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."personal_memory_media" FROM "anon", "authenticated";

CREATE TABLE "public"."personal_memory" (
  "personal_memory_id"  uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "participant_id"      uuid                     NOT NULL,
  "composition_version" integer                  NOT NULL,
  "composition_jsonb"   jsonb                    NOT NULL,
  "created_at"          timestamp with time zone NOT NULL DEFAULT transaction_timestamp(),
  "completed_at"        timestamp with time zone NOT NULL DEFAULT transaction_timestamp(),
  CONSTRAINT "chk_personal_memory_completed_at" CHECK ((completed_at >= created_at)),
  CONSTRAINT "chk_personal_memory_composition_jsonb_object" CHECK ((jsonb_typeof(composition_jsonb) = 'object'::text)),
  CONSTRAINT "chk_personal_memory_composition_version" CHECK ((composition_version > 0)),
  CONSTRAINT "personal_memory_pkey" PRIMARY KEY (personal_memory_id)
);

ALTER TABLE "public"."personal_memory"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."personal_memory" FROM "anon", "authenticated";

ALTER TABLE "public"."media_asset"
  ADD CONSTRAINT "fk_media_asset_uploader" FOREIGN KEY (uploaded_by_participant_id) REFERENCES public.participant(participant_id) ON DELETE RESTRICT;

ALTER TABLE "public"."personal_memory"
  ADD CONSTRAINT "fk_personal_memory_participant" FOREIGN KEY (participant_id) REFERENCES public.participant(participant_id) ON DELETE RESTRICT;

ALTER TABLE "public"."personal_memory_media"
  ADD CONSTRAINT "fk_personal_memory_media_asset" FOREIGN KEY (media_asset_id) REFERENCES public.media_asset(media_asset_id) ON DELETE RESTRICT;

ALTER TABLE "public"."personal_memory_media"
  ADD CONSTRAINT "fk_personal_memory_media_memory" FOREIGN KEY (personal_memory_id) REFERENCES public.personal_memory(personal_memory_id) ON DELETE RESTRICT;

CREATE INDEX idx_media_asset_uploader ON public.media_asset USING btree (uploaded_by_participant_id);

CREATE INDEX idx_personal_memory_media_asset ON public.personal_memory_media USING btree (media_asset_id);

CREATE INDEX idx_personal_memory_participant ON public.personal_memory USING btree (participant_id);

REVOKE ALL ON TABLE "public"."media_asset" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."media_asset" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."media_asset" TO "service_role";

REVOKE ALL ON TABLE "public"."personal_memory" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."personal_memory" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."personal_memory" TO "service_role";

REVOKE ALL ON TABLE "public"."personal_memory_media" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."personal_memory_media" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."personal_memory_media" TO "service_role";
