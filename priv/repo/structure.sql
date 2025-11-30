--
-- PostgreSQL database dump
--

\restrict cm5H7uGwwFkbWsQiuBHz6hSXwETEBE3peQNZ4uYzY8QMCFm0TQllgJBudOzSQ8K

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requests (
    request_id character varying(255) NOT NULL,
    method character varying(10) NOT NULL,
    path text NOT NULL,
    status_code integer NOT NULL,
    duration_ms integer NOT NULL,
    user_agent text,
    remote_ip character varying(45),
    referer text,
    device_type character varying(20),
    session_id character varying(255),
    session_page_views integer,
    inserted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: set_song_variants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.set_song_variants (
    id bigint NOT NULL,
    set_song_id bigint NOT NULL,
    variant_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    manual boolean DEFAULT false NOT NULL,
    user_id bigint
);


--
-- Name: set_song_variants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.set_song_variants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: set_song_variants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.set_song_variants_id_seq OWNED BY public.set_song_variants.id;


--
-- Name: set_songs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.set_songs (
    id bigint NOT NULL,
    title character varying(255),
    urn character varying(255),
    duration integer,
    set_id bigint,
    song_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: set_songs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.set_songs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: set_songs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.set_songs_id_seq OWNED BY public.set_songs.id;


--
-- Name: sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sets (
    id bigint NOT NULL,
    title character varying(255),
    thumbnail character varying(255),
    urn character varying(255),
    date date,
    release_date date,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: sets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sets_id_seq OWNED BY public.sets.id;


--
-- Name: song_merges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.song_merges (
    id bigint NOT NULL,
    source_title character varying(255) NOT NULL,
    target_title character varying(255) NOT NULL,
    target_song_id bigint,
    user_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: song_merges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.song_merges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: song_merges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.song_merges_id_seq OWNED BY public.song_merges.id;


--
-- Name: songs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.songs (
    id bigint NOT NULL,
    title character varying(255),
    release_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    display_name character varying(255)
);


--
-- Name: songs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.songs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: songs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.songs_id_seq OWNED BY public.songs.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    username character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role character varying(255) DEFAULT 'user'::character varying NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: variants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.variants (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    category character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: variants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.variants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: variants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.variants_id_seq OWNED BY public.variants.id;


--
-- Name: set_song_variants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.set_song_variants ALTER COLUMN id SET DEFAULT nextval('public.set_song_variants_id_seq'::regclass);


--
-- Name: set_songs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.set_songs ALTER COLUMN id SET DEFAULT nextval('public.set_songs_id_seq'::regclass);


--
-- Name: sets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sets ALTER COLUMN id SET DEFAULT nextval('public.sets_id_seq'::regclass);


--
-- Name: song_merges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.song_merges ALTER COLUMN id SET DEFAULT nextval('public.song_merges_id_seq'::regclass);


--
-- Name: songs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.songs ALTER COLUMN id SET DEFAULT nextval('public.songs_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: variants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variants ALTER COLUMN id SET DEFAULT nextval('public.variants_id_seq'::regclass);


--
-- Name: requests requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT requests_pkey PRIMARY KEY (request_id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: set_song_variants set_song_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.set_song_variants
    ADD CONSTRAINT set_song_variants_pkey PRIMARY KEY (id);


--
-- Name: set_songs set_songs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.set_songs
    ADD CONSTRAINT set_songs_pkey PRIMARY KEY (id);


--
-- Name: sets sets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sets
    ADD CONSTRAINT sets_pkey PRIMARY KEY (id);


--
-- Name: song_merges song_merges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.song_merges
    ADD CONSTRAINT song_merges_pkey PRIMARY KEY (id);


--
-- Name: songs songs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.songs
    ADD CONSTRAINT songs_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: variants variants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variants
    ADD CONSTRAINT variants_pkey PRIMARY KEY (id);


--
-- Name: idx_requests_date_method; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requests_date_method ON public.requests USING btree (inserted_at, method);


--
-- Name: idx_requests_date_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requests_date_status ON public.requests USING btree (inserted_at, status_code);


--
-- Name: idx_requests_device_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requests_device_type ON public.requests USING btree (device_type);


--
-- Name: idx_requests_inserted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requests_inserted_at ON public.requests USING btree (inserted_at);


--
-- Name: idx_requests_method; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requests_method ON public.requests USING btree (method);


--
-- Name: idx_requests_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requests_path ON public.requests USING btree (path);


--
-- Name: idx_requests_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requests_session_id ON public.requests USING btree (session_id);


--
-- Name: idx_requests_status_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requests_status_code ON public.requests USING btree (status_code);


--
-- Name: set_song_variants_set_song_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX set_song_variants_set_song_id_index ON public.set_song_variants USING btree (set_song_id);


--
-- Name: set_song_variants_set_song_id_variant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX set_song_variants_set_song_id_variant_id_index ON public.set_song_variants USING btree (set_song_id, variant_id);


--
-- Name: set_song_variants_variant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX set_song_variants_variant_id_index ON public.set_song_variants USING btree (variant_id);


--
-- Name: set_songs_set_id_urn_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX set_songs_set_id_urn_index ON public.set_songs USING btree (set_id, urn);


--
-- Name: set_songs_title_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX set_songs_title_index ON public.set_songs USING btree (title);


--
-- Name: sets_title_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sets_title_index ON public.sets USING btree (title);


--
-- Name: song_merges_target_song_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX song_merges_target_song_id_index ON public.song_merges USING btree (target_song_id);


--
-- Name: song_merges_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX song_merges_user_id_index ON public.song_merges USING btree (user_id);


--
-- Name: songs_title_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX songs_title_index ON public.songs USING btree (title);


--
-- Name: users_username_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_username_index ON public.users USING btree (username);


--
-- Name: variants_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX variants_name_index ON public.variants USING btree (name);


--
-- Name: set_song_variants set_song_variants_set_song_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.set_song_variants
    ADD CONSTRAINT set_song_variants_set_song_id_fkey FOREIGN KEY (set_song_id) REFERENCES public.set_songs(id) ON DELETE CASCADE;


--
-- Name: set_song_variants set_song_variants_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.set_song_variants
    ADD CONSTRAINT set_song_variants_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: set_song_variants set_song_variants_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.set_song_variants
    ADD CONSTRAINT set_song_variants_variant_id_fkey FOREIGN KEY (variant_id) REFERENCES public.variants(id) ON DELETE CASCADE;


--
-- Name: set_songs set_songs_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.set_songs
    ADD CONSTRAINT set_songs_set_id_fkey FOREIGN KEY (set_id) REFERENCES public.sets(id);


--
-- Name: set_songs set_songs_song_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.set_songs
    ADD CONSTRAINT set_songs_song_id_fkey FOREIGN KEY (song_id) REFERENCES public.songs(id);


--
-- Name: song_merges song_merges_target_song_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.song_merges
    ADD CONSTRAINT song_merges_target_song_id_fkey FOREIGN KEY (target_song_id) REFERENCES public.songs(id) ON DELETE SET NULL;


--
-- Name: song_merges song_merges_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.song_merges
    ADD CONSTRAINT song_merges_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: songs songs_release_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.songs
    ADD CONSTRAINT songs_release_id_fkey FOREIGN KEY (release_id) REFERENCES public.sets(id);


--
-- PostgreSQL database dump complete
--

\unrestrict cm5H7uGwwFkbWsQiuBHz6hSXwETEBE3peQNZ4uYzY8QMCFm0TQllgJBudOzSQ8K

INSERT INTO public."schema_migrations" (version) VALUES (20231103033836);
INSERT INTO public."schema_migrations" (version) VALUES (20231109035707);
INSERT INTO public."schema_migrations" (version) VALUES (20251130034651);
INSERT INTO public."schema_migrations" (version) VALUES (20251130050237);
INSERT INTO public."schema_migrations" (version) VALUES (20251130050632);
INSERT INTO public."schema_migrations" (version) VALUES (20251130054643);
