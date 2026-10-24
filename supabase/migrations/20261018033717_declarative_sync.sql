CREATE TABLE "public"."participant_access_capability" (
  "participant_access_capability_id" uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "participant_id"                   uuid                     NOT NULL,
  "capability_type"                  text                     NOT NULL,
  "token_hash"                       bytea                    NOT NULL,
  "created_at"                       timestamp with time zone NOT NULL DEFAULT transaction_timestamp(),
  "expires_at"                       timestamp with time zone NOT NULL,
  "consumed_at"                      timestamp with time zone,
  "revoked_at"                       timestamp with time zone,
  CONSTRAINT "chk_participant_access_capability_consumed_at" CHECK (((consumed_at IS NULL) OR (consumed_at >= created_at))),
  CONSTRAINT "chk_participant_access_capability_expiry" CHECK ((expires_at > created_at)),
  CONSTRAINT "chk_participant_access_capability_revoked_at" CHECK (((revoked_at IS NULL) OR (revoked_at >= created_at))),
  CONSTRAINT "chk_participant_access_capability_token_hash" CHECK ((octet_length(token_hash) = 32)),
  CONSTRAINT "chk_participant_access_capability_type" CHECK ((capability_type = ANY (ARRAY['INVITE'::text, 'RECOVERY'::text]))),
  CONSTRAINT "participant_access_capability_pkey" PRIMARY KEY (participant_access_capability_id),
  CONSTRAINT "uq_participant_access_capability_token_hash" UNIQUE (token_hash)
);

ALTER TABLE "public"."participant_access_capability"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."participant_access_capability" FROM "anon", "authenticated";

CREATE TABLE "public"."participant" (
  "participant_id" uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "display_name"   text                     NOT NULL,
  "created_at"     timestamp with time zone NOT NULL DEFAULT transaction_timestamp(),
  CONSTRAINT "chk_participant_display_name_not_blank" CHECK ((btrim(display_name) <> ''::text)),
  CONSTRAINT "participant_pkey" PRIMARY KEY (participant_id)
);

ALTER TABLE "public"."participant"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."participant" FROM "anon", "authenticated";

CREATE TABLE "public"."protected_access_session" (
  "protected_access_session_id" uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "participant_id"              uuid                     NOT NULL,
  "session_token_hash"          bytea                    NOT NULL,
  "created_at"                  timestamp with time zone NOT NULL DEFAULT transaction_timestamp(),
  "expires_at"                  timestamp with time zone NOT NULL,
  "revoked_at"                  timestamp with time zone,
  CONSTRAINT "chk_protected_access_session_expiry" CHECK ((expires_at > created_at)),
  CONSTRAINT "chk_protected_access_session_revoked_at" CHECK (((revoked_at IS NULL) OR (revoked_at >= created_at))),
  CONSTRAINT "chk_protected_access_session_token_hash" CHECK ((octet_length(session_token_hash) = 32)),
  CONSTRAINT "protected_access_session_pkey" PRIMARY KEY (protected_access_session_id),
  CONSTRAINT "uq_protected_access_session_token_hash" UNIQUE (session_token_hash)
);

ALTER TABLE "public"."protected_access_session"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."protected_access_session" FROM "anon", "authenticated";

ALTER TABLE "public"."participant_access_capability"
  ADD CONSTRAINT "fk_participant_access_capability_participant" FOREIGN KEY (participant_id) REFERENCES public.participant(participant_id) ON DELETE RESTRICT;

ALTER TABLE "public"."protected_access_session"
  ADD CONSTRAINT "fk_protected_access_session_participant" FOREIGN KEY (participant_id) REFERENCES public.participant(participant_id) ON DELETE RESTRICT;

CREATE INDEX idx_participant_access_capability_participant ON public.participant_access_capability USING btree (participant_id);

CREATE INDEX idx_protected_access_session_participant ON public.protected_access_session USING btree (participant_id);

REVOKE ALL ON TABLE "public"."participant" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."participant" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."participant" TO "service_role";

REVOKE ALL ON TABLE "public"."participant_access_capability" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."participant_access_capability" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."participant_access_capability" TO "service_role";

REVOKE ALL ON TABLE "public"."protected_access_session" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."protected_access_session" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."protected_access_session" TO "service_role";
