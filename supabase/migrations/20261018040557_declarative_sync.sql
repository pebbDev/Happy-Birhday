CREATE TABLE "public"."async_response_media" (
  "async_response_id" uuid     NOT NULL,
  "cut_position"      smallint NOT NULL,
  "media_asset_id"    uuid     NOT NULL,
  CONSTRAINT "chk_async_response_media_cut_position" CHECK (((cut_position >= 1) AND (cut_position <= 4))),
  CONSTRAINT "pk_async_response_media" PRIMARY KEY (async_response_id, cut_position),
  CONSTRAINT "uq_async_response_media_asset" UNIQUE (async_response_id, media_asset_id)
);

ALTER TABLE "public"."async_response_media"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."async_response_media" FROM "anon", "authenticated";

CREATE TABLE "public"."async_response" (
  "async_response_id"        uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "session_participation_id" uuid                     NOT NULL,
  "created_at"               timestamp with time zone NOT NULL DEFAULT transaction_timestamp(),
  "updated_at"               timestamp with time zone NOT NULL DEFAULT transaction_timestamp(),
  CONSTRAINT "async_response_pkey" PRIMARY KEY (async_response_id),
  CONSTRAINT "chk_async_response_updated_at" CHECK ((updated_at >= created_at)),
  CONSTRAINT "uq_async_response_participation" UNIQUE (session_participation_id)
);

ALTER TABLE "public"."async_response"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."async_response" FROM "anon", "authenticated";

CREATE TABLE "public"."async_session" (
  "async_session_id"                        uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "state"                                   text                     NOT NULL,
  "resource_version"                        bigint                   NOT NULL DEFAULT 0,
  "current_editor_session_participation_id" uuid,
  "active_editing_access_session_id"        uuid,
  "created_at"                              timestamp with time zone NOT NULL DEFAULT transaction_timestamp(),
  "invite_ready_at"                         timestamp with time zone,
  "response_start_deadline_at"              timestamp with time zone,
  "responding_started_at"                   timestamp with time zone,
  "responding_deadline_at"                  timestamp with time zone,
  "completed_at"                            timestamp with time zone,
  "expired_at"                              timestamp with time zone,
  CONSTRAINT "async_session_pkey" PRIMARY KEY (async_session_id),
  CONSTRAINT "chk_async_session_resource_version" CHECK ((resource_version >= 0)),
  CONSTRAINT "chk_async_session_responding_deadline" CHECK (((responding_deadline_at IS NULL) OR ((responding_started_at IS
    NOT NULL) AND (responding_deadline_at > responding_started_at)))),
  CONSTRAINT "chk_async_session_start_deadline" CHECK (((response_start_deadline_at IS NULL) OR ((invite_ready_at IS
    NOT NULL) AND (response_start_deadline_at > invite_ready_at)))),
  CONSTRAINT "chk_async_session_state" CHECK ((state = ANY (ARRAY['INITIATING'::text, 'WAITING'::text, 'RESPONDING'::text, 'COMPLETED'::text, 'EXPIRED'::text]))),
  CONSTRAINT "chk_async_session_terminal_outcome" CHECK ((NOT ((completed_at IS NOT NULL) AND (expired_at IS NOT NULL))))
);

ALTER TABLE "public"."async_session"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."async_session" FROM "anon", "authenticated";

CREATE TABLE "public"."canonical_memory_media" (
  "canonical_memory_id"      uuid     NOT NULL,
  "session_participation_id" uuid     NOT NULL,
  "cut_position"             smallint NOT NULL,
  "media_asset_id"           uuid     NOT NULL,
  CONSTRAINT "chk_canonical_memory_media_cut_position" CHECK (((cut_position >= 1) AND (cut_position <= 4))),
  CONSTRAINT "pk_canonical_memory_media" PRIMARY KEY (canonical_memory_id, cut_position, session_participation_id),
  CONSTRAINT "uq_canonical_memory_media_asset" UNIQUE (canonical_memory_id, media_asset_id)
);

ALTER TABLE "public"."canonical_memory_media"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."canonical_memory_media" FROM "anon", "authenticated";

CREATE TABLE "public"."canonical_memory" (
  "canonical_memory_id" uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "async_session_id"    uuid                     NOT NULL,
  "created_at"          timestamp with time zone NOT NULL DEFAULT transaction_timestamp(),
  CONSTRAINT "canonical_memory_pkey" PRIMARY KEY (canonical_memory_id),
  CONSTRAINT "uq_canonical_memory_session" UNIQUE (async_session_id)
);

ALTER TABLE "public"."canonical_memory"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."canonical_memory" FROM "anon", "authenticated";

CREATE TABLE "public"."responder_continuation_authority" (
  "continuation_authority_id" uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "session_participation_id"  uuid                     NOT NULL,
  "token_hash"                bytea                    NOT NULL,
  "created_at"                timestamp with time zone NOT NULL DEFAULT transaction_timestamp(),
  "expires_at"                timestamp with time zone,
  "revoked_at"                timestamp with time zone,
  CONSTRAINT "chk_responder_continuation_expiry" CHECK (((expires_at IS NULL) OR (expires_at > created_at))),
  CONSTRAINT "chk_responder_continuation_revocation" CHECK (((revoked_at IS NULL) OR (revoked_at >= created_at))),
  CONSTRAINT "chk_responder_continuation_token_hash" CHECK ((octet_length(token_hash) = 32)),
  CONSTRAINT "responder_continuation_authority_pkey" PRIMARY KEY (continuation_authority_id),
  CONSTRAINT "uq_responder_continuation_participation" UNIQUE (session_participation_id),
  CONSTRAINT "uq_responder_continuation_token_hash" UNIQUE (token_hash)
);

ALTER TABLE "public"."responder_continuation_authority"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."responder_continuation_authority" FROM "anon", "authenticated";

CREATE TABLE "public"."session_participation" (
  "session_participation_id" uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "async_session_id"         uuid                     NOT NULL,
  "participant_id"           uuid                     NOT NULL,
  "role"                     text                     NOT NULL,
  "created_at"               timestamp with time zone NOT NULL DEFAULT transaction_timestamp(),
  CONSTRAINT "chk_session_participation_role" CHECK ((role = ANY (ARRAY['INITIATOR'::text, 'RESPONDER'::text]))),
  CONSTRAINT "session_participation_pkey" PRIMARY KEY (session_participation_id),
  CONSTRAINT "uq_session_participation_identity_session" UNIQUE (session_participation_id, async_session_id),
  CONSTRAINT "uq_session_participation_participant" UNIQUE (async_session_id, participant_id),
  CONSTRAINT "uq_session_participation_role" UNIQUE (async_session_id, ROLE)
);

ALTER TABLE "public"."session_participation"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."session_participation" FROM "anon", "authenticated";

ALTER TABLE "public"."async_response_media"
  ADD CONSTRAINT "fk_async_response_media_asset" FOREIGN KEY (media_asset_id) REFERENCES public.media_asset(media_asset_id) ON DELETE RESTRICT;

ALTER TABLE "public"."async_response_media"
  ADD CONSTRAINT "fk_async_response_media_response" FOREIGN KEY (async_response_id) REFERENCES public.async_response(async_response_id) ON DELETE CASCADE;

ALTER TABLE "public"."async_session"
  ADD CONSTRAINT "fk_async_session_active_access_session" FOREIGN KEY (active_editing_access_session_id) REFERENCES public.protected_access_session(protected_access_session_id)
    ON DELETE RESTRICT;

ALTER TABLE "public"."canonical_memory"
  ADD CONSTRAINT "fk_canonical_memory_session" FOREIGN KEY (async_session_id) REFERENCES public.async_session(async_session_id) ON DELETE RESTRICT;

ALTER TABLE "public"."canonical_memory_media"
  ADD CONSTRAINT "fk_canonical_memory_media_asset" FOREIGN KEY (media_asset_id) REFERENCES public.media_asset(media_asset_id) ON DELETE RESTRICT;

ALTER TABLE "public"."canonical_memory_media"
  ADD CONSTRAINT "fk_canonical_memory_media_memory" FOREIGN KEY (canonical_memory_id) REFERENCES public.canonical_memory(canonical_memory_id) ON DELETE RESTRICT;

ALTER TABLE "public"."session_participation"
  ADD CONSTRAINT "fk_session_participation_participant" FOREIGN KEY (participant_id) REFERENCES public.participant(participant_id) ON DELETE RESTRICT;

ALTER TABLE "public"."session_participation"
  ADD CONSTRAINT "fk_session_participation_session" FOREIGN KEY (async_session_id) REFERENCES public.async_session(async_session_id) ON DELETE RESTRICT;

ALTER TABLE "public"."async_response"
  ADD CONSTRAINT "fk_async_response_participation" FOREIGN KEY (session_participation_id) REFERENCES public.session_participation(session_participation_id) ON DELETE CASCADE;

ALTER TABLE "public"."canonical_memory_media"
  ADD CONSTRAINT "fk_canonical_memory_media_participation" FOREIGN KEY (session_participation_id) REFERENCES public.session_participation(session_participation_id)
    ON DELETE RESTRICT;

ALTER TABLE "public"."responder_continuation_authority"
  ADD CONSTRAINT "fk_responder_continuation_participation" FOREIGN KEY (session_participation_id) REFERENCES public.session_participation(session_participation_id)
    ON DELETE CASCADE;

ALTER TABLE "public"."async_session"
  ADD CONSTRAINT "fk_async_session_current_editor" FOREIGN KEY (current_editor_session_participation_id, async_session_id)
    REFERENCES public.session_participation(session_participation_id, async_session_id) ON DELETE RESTRICT;

CREATE INDEX idx_async_response_media_media_asset ON public.async_response_media USING btree (media_asset_id);

CREATE INDEX idx_canonical_memory_media_media_asset ON public.canonical_memory_media USING btree (media_asset_id);

CREATE INDEX idx_canonical_memory_media_participation ON public.canonical_memory_media USING btree (session_participation_id);

CREATE INDEX idx_session_participation_participant ON public.session_participation USING btree (participant_id);

REVOKE ALL ON TABLE "public"."async_response" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."async_response" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."async_response" TO "service_role";

REVOKE ALL ON TABLE "public"."async_response_media" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."async_response_media" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."async_response_media" TO "service_role";

REVOKE ALL ON TABLE "public"."async_session" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."async_session" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."async_session" TO "service_role";

REVOKE ALL ON TABLE "public"."canonical_memory" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."canonical_memory" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."canonical_memory" TO "service_role";

REVOKE ALL ON TABLE "public"."canonical_memory_media" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."canonical_memory_media" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."canonical_memory_media" TO "service_role";

REVOKE ALL ON TABLE "public"."responder_continuation_authority" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."responder_continuation_authority" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."responder_continuation_authority" TO "service_role";

REVOKE ALL ON TABLE "public"."session_participation" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."session_participation" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."session_participation" TO "service_role";
