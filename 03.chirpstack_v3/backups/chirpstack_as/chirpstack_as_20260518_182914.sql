--
-- PostgreSQL database dump
--

\restrict fmGA6Q4gUy4fs9ajksMFz874I60U4eU4QITWZV6WpB5ryqSmkGE3HpxfQ2KmQ5n

-- Dumped from database version 14.22
-- Dumped by pg_dump version 16.13 (Ubuntu 16.13-0ubuntu0.24.04.1)

-- Started on 2026-05-18 18:29:21 -03

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE IF EXISTS chirpstack_as;
--
-- TOC entry 3785 (class 1262 OID 16385)
-- Name: chirpstack_as; Type: DATABASE; Schema: -; Owner: chirpstack_as
--

CREATE DATABASE chirpstack_as WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE chirpstack_as OWNER TO chirpstack_as;

\unrestrict fmGA6Q4gUy4fs9ajksMFz874I60U4eU4QITWZV6WpB5ryqSmkGE3HpxfQ2KmQ5n
\connect chirpstack_as
\restrict fmGA6Q4gUy4fs9ajksMFz874I60U4eU4QITWZV6WpB5ryqSmkGE3HpxfQ2KmQ5n

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 3 (class 3079 OID 16467)
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- TOC entry 3787 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- TOC entry 2 (class 3079 OID 16386)
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- TOC entry 3788 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 237 (class 1259 OID 17416)
-- Name: api_key; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public.api_key (
    id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    is_admin boolean DEFAULT false NOT NULL,
    organization_id bigint,
    application_id bigint
);


ALTER TABLE public.api_key OWNER TO chirpstack_as;

--
-- TOC entry 213 (class 1259 OID 16714)
-- Name: application; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public.application (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    description text NOT NULL,
    organization_id bigint NOT NULL,
    service_profile_id uuid NOT NULL,
    payload_codec text DEFAULT ''::text NOT NULL,
    payload_encoder_script text DEFAULT ''::text NOT NULL,
    payload_decoder_script text DEFAULT ''::text NOT NULL,
    mqtt_tls_cert bytea
);


ALTER TABLE public.application OWNER TO chirpstack_as;

--
-- TOC entry 212 (class 1259 OID 16713)
-- Name: application_id_seq; Type: SEQUENCE; Schema: public; Owner: chirpstack_as
--

CREATE SEQUENCE public.application_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.application_id_seq OWNER TO chirpstack_as;

--
-- TOC entry 3789 (class 0 OID 0)
-- Dependencies: 212
-- Name: application_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chirpstack_as
--

ALTER SEQUENCE public.application_id_seq OWNED BY public.application.id;


--
-- TOC entry 236 (class 1259 OID 17380)
-- Name: code_migration; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public.code_migration (
    id text NOT NULL,
    applied_at timestamp with time zone NOT NULL
);


ALTER TABLE public.code_migration OWNER TO chirpstack_as;

--
-- TOC entry 231 (class 1259 OID 16988)
-- Name: device; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public.device (
    dev_eui bytea NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    application_id bigint NOT NULL,
    device_profile_id uuid NOT NULL,
    name character varying(100) NOT NULL,
    description text NOT NULL,
    last_seen_at timestamp with time zone,
    device_status_battery numeric(5,2),
    device_status_margin integer,
    latitude double precision,
    longitude double precision,
    altitude double precision,
    device_status_external_power_source boolean NOT NULL,
    dr smallint,
    variables public.hstore,
    tags public.hstore,
    dev_addr bytea NOT NULL,
    app_s_key bytea NOT NULL
);


ALTER TABLE public.device OWNER TO chirpstack_as;

--
-- TOC entry 232 (class 1259 OID 17011)
-- Name: device_keys; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public.device_keys (
    dev_eui bytea NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    nwk_key bytea NOT NULL,
    join_nonce integer NOT NULL,
    app_key bytea NOT NULL
);


ALTER TABLE public.device_keys OWNER TO chirpstack_as;

--
-- TOC entry 235 (class 1259 OID 17210)
-- Name: device_multicast_group; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public.device_multicast_group (
    dev_eui bytea NOT NULL,
    multicast_group_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.device_multicast_group OWNER TO chirpstack_as;

--
-- TOC entry 230 (class 1259 OID 16969)
-- Name: device_profile; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public.device_profile (
    device_profile_id uuid NOT NULL,
    network_server_id bigint NOT NULL,
    organization_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    payload_codec text NOT NULL,
    payload_encoder_script text NOT NULL,
    payload_decoder_script text NOT NULL,
    tags public.hstore,
    uplink_interval bigint NOT NULL
);


ALTER TABLE public.device_profile OWNER TO chirpstack_as;

--
-- TOC entry 220 (class 1259 OID 16831)
-- Name: gateway; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public.gateway (
    mac bytea NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    description text NOT NULL,
    organization_id bigint NOT NULL,
    ping boolean DEFAULT false NOT NULL,
    last_ping_id bigint,
    last_ping_sent_at timestamp with time zone,
    network_server_id bigint NOT NULL,
    gateway_profile_id uuid,
    first_seen_at timestamp with time zone,
    last_seen_at timestamp with time zone,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    altitude double precision NOT NULL,
    tags public.hstore,
    metadata public.hstore,
    service_profile_id uuid
);


ALTER TABLE public.gateway OWNER TO chirpstack_as;

--
-- TOC entry 224 (class 1259 OID 16886)
-- Name: gateway_ping; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public.gateway_ping (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    gateway_mac bytea NOT NULL,
    frequency integer NOT NULL,
    dr integer NOT NULL
);


ALTER TABLE public.gateway_ping OWNER TO chirpstack_as;

--
-- TOC entry 223 (class 1259 OID 16885)
-- Name: gateway_ping_id_seq; Type: SEQUENCE; Schema: public; Owner: chirpstack_as
--

CREATE SEQUENCE public.gateway_ping_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gateway_ping_id_seq OWNER TO chirpstack_as;

--
-- TOC entry 3790 (class 0 OID 0)
-- Dependencies: 223
-- Name: gateway_ping_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chirpstack_as
--

ALTER SEQUENCE public.gateway_ping_id_seq OWNED BY public.gateway_ping.id;


--
-- TOC entry 226 (class 1259 OID 16902)
-- Name: gateway_ping_rx; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public.gateway_ping_rx (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    ping_id bigint NOT NULL,
    gateway_mac bytea NOT NULL,
    received_at timestamp with time zone,
    rssi integer NOT NULL,
    lora_snr numeric(3,1) NOT NULL,
    location point,
    altitude double precision
);


ALTER TABLE public.gateway_ping_rx OWNER TO chirpstack_as;

--
-- TOC entry 225 (class 1259 OID 16901)
-- Name: gateway_ping_rx_id_seq; Type: SEQUENCE; Schema: public; Owner: chirpstack_as
--

CREATE SEQUENCE public.gateway_ping_rx_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gateway_ping_rx_id_seq OWNER TO chirpstack_as;

--
-- TOC entry 3791 (class 0 OID 0)
-- Dependencies: 225
-- Name: gateway_ping_rx_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chirpstack_as
--

ALTER SEQUENCE public.gateway_ping_rx_id_seq OWNED BY public.gateway_ping_rx.id;


--
-- TOC entry 233 (class 1259 OID 17146)
-- Name: gateway_profile; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public.gateway_profile (
    gateway_profile_id uuid NOT NULL,
    network_server_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    stats_interval bigint NOT NULL
);


ALTER TABLE public.gateway_profile OWNER TO chirpstack_as;

--
-- TOC entry 222 (class 1259 OID 16864)
-- Name: integration; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public.integration (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    application_id bigint NOT NULL,
    kind character varying(20) NOT NULL,
    settings jsonb
);


ALTER TABLE public.integration OWNER TO chirpstack_as;

--
-- TOC entry 221 (class 1259 OID 16863)
-- Name: integration_id_seq; Type: SEQUENCE; Schema: public; Owner: chirpstack_as
--

CREATE SEQUENCE public.integration_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.integration_id_seq OWNER TO chirpstack_as;

--
-- TOC entry 3792 (class 0 OID 0)
-- Dependencies: 221
-- Name: integration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chirpstack_as
--

ALTER SEQUENCE public.integration_id_seq OWNED BY public.integration.id;


--
-- TOC entry 234 (class 1259 OID 17196)
-- Name: multicast_group; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public.multicast_group (
    id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    mc_app_s_key bytea,
    application_id bigint NOT NULL
);


ALTER TABLE public.multicast_group OWNER TO chirpstack_as;

--
-- TOC entry 228 (class 1259 OID 16942)
-- Name: network_server; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public.network_server (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    server character varying(255) NOT NULL,
    ca_cert text DEFAULT ''::text NOT NULL,
    tls_cert text DEFAULT ''::text NOT NULL,
    tls_key text DEFAULT ''::text NOT NULL,
    routing_profile_ca_cert text DEFAULT ''::text NOT NULL,
    routing_profile_tls_cert text DEFAULT ''::text NOT NULL,
    routing_profile_tls_key text DEFAULT ''::text NOT NULL,
    gateway_discovery_enabled boolean DEFAULT false NOT NULL,
    gateway_discovery_interval integer DEFAULT 0 NOT NULL,
    gateway_discovery_tx_frequency integer DEFAULT 0 NOT NULL,
    gateway_discovery_dr smallint DEFAULT 0 NOT NULL
);


ALTER TABLE public.network_server OWNER TO chirpstack_as;

--
-- TOC entry 227 (class 1259 OID 16941)
-- Name: network_server_id_seq; Type: SEQUENCE; Schema: public; Owner: chirpstack_as
--

CREATE SEQUENCE public.network_server_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.network_server_id_seq OWNER TO chirpstack_as;

--
-- TOC entry 3793 (class 0 OID 0)
-- Dependencies: 227
-- Name: network_server_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chirpstack_as
--

ALTER SEQUENCE public.network_server_id_seq OWNED BY public.network_server.id;


--
-- TOC entry 217 (class 1259 OID 16802)
-- Name: organization; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public.organization (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    display_name character varying(100) NOT NULL,
    can_have_gateways boolean NOT NULL,
    max_device_count integer NOT NULL,
    max_gateway_count integer NOT NULL
);


ALTER TABLE public.organization OWNER TO chirpstack_as;

--
-- TOC entry 216 (class 1259 OID 16801)
-- Name: organization_id_seq; Type: SEQUENCE; Schema: public; Owner: chirpstack_as
--

CREATE SEQUENCE public.organization_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.organization_id_seq OWNER TO chirpstack_as;

--
-- TOC entry 3794 (class 0 OID 0)
-- Dependencies: 216
-- Name: organization_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chirpstack_as
--

ALTER SEQUENCE public.organization_id_seq OWNED BY public.organization.id;


--
-- TOC entry 219 (class 1259 OID 16811)
-- Name: organization_user; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public.organization_user (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    user_id bigint NOT NULL,
    organization_id bigint NOT NULL,
    is_admin boolean NOT NULL,
    is_device_admin boolean NOT NULL,
    is_gateway_admin boolean NOT NULL
);


ALTER TABLE public.organization_user OWNER TO chirpstack_as;

--
-- TOC entry 218 (class 1259 OID 16810)
-- Name: organization_user_id_seq; Type: SEQUENCE; Schema: public; Owner: chirpstack_as
--

CREATE SEQUENCE public.organization_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.organization_user_id_seq OWNER TO chirpstack_as;

--
-- TOC entry 3795 (class 0 OID 0)
-- Dependencies: 218
-- Name: organization_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chirpstack_as
--

ALTER SEQUENCE public.organization_user_id_seq OWNED BY public.organization_user.id;


--
-- TOC entry 211 (class 1259 OID 16595)
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    dirty boolean NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO chirpstack_as;

--
-- TOC entry 229 (class 1259 OID 16950)
-- Name: service_profile; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public.service_profile (
    service_profile_id uuid NOT NULL,
    organization_id bigint NOT NULL,
    network_server_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.service_profile OWNER TO chirpstack_as;

--
-- TOC entry 215 (class 1259 OID 16768)
-- Name: user; Type: TABLE; Schema: public; Owner: chirpstack_as
--

CREATE TABLE public."user" (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    email text NOT NULL,
    password_hash character varying(200) NOT NULL,
    session_ttl bigint NOT NULL,
    is_active boolean NOT NULL,
    is_admin boolean NOT NULL,
    email_old text DEFAULT ''::text NOT NULL,
    note text NOT NULL,
    external_id text,
    email_verified boolean NOT NULL
);


ALTER TABLE public."user" OWNER TO chirpstack_as;

--
-- TOC entry 214 (class 1259 OID 16767)
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: chirpstack_as
--

CREATE SEQUENCE public.user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_id_seq OWNER TO chirpstack_as;

--
-- TOC entry 3796 (class 0 OID 0)
-- Dependencies: 214
-- Name: user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chirpstack_as
--

ALTER SEQUENCE public.user_id_seq OWNED BY public."user".id;


--
-- TOC entry 3477 (class 2604 OID 16717)
-- Name: application id; Type: DEFAULT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.application ALTER COLUMN id SET DEFAULT nextval('public.application_id_seq'::regclass);


--
-- TOC entry 3487 (class 2604 OID 16889)
-- Name: gateway_ping id; Type: DEFAULT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.gateway_ping ALTER COLUMN id SET DEFAULT nextval('public.gateway_ping_id_seq'::regclass);


--
-- TOC entry 3488 (class 2604 OID 16905)
-- Name: gateway_ping_rx id; Type: DEFAULT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.gateway_ping_rx ALTER COLUMN id SET DEFAULT nextval('public.gateway_ping_rx_id_seq'::regclass);


--
-- TOC entry 3486 (class 2604 OID 16867)
-- Name: integration id; Type: DEFAULT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.integration ALTER COLUMN id SET DEFAULT nextval('public.integration_id_seq'::regclass);


--
-- TOC entry 3489 (class 2604 OID 16945)
-- Name: network_server id; Type: DEFAULT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.network_server ALTER COLUMN id SET DEFAULT nextval('public.network_server_id_seq'::regclass);


--
-- TOC entry 3483 (class 2604 OID 16805)
-- Name: organization id; Type: DEFAULT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.organization ALTER COLUMN id SET DEFAULT nextval('public.organization_id_seq'::regclass);


--
-- TOC entry 3484 (class 2604 OID 16814)
-- Name: organization_user id; Type: DEFAULT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.organization_user ALTER COLUMN id SET DEFAULT nextval('public.organization_user_id_seq'::regclass);


--
-- TOC entry 3481 (class 2604 OID 16771)
-- Name: user id; Type: DEFAULT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public."user" ALTER COLUMN id SET DEFAULT nextval('public.user_id_seq'::regclass);


--
-- TOC entry 3779 (class 0 OID 17416)
-- Dependencies: 237
-- Data for Name: api_key; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public.api_key (id, created_at, name, is_admin, organization_id, application_id) FROM stdin;
\.


--
-- TOC entry 3755 (class 0 OID 16714)
-- Dependencies: 213
-- Data for Name: application; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public.application (id, name, description, organization_id, service_profile_id, payload_codec, payload_encoder_script, payload_decoder_script, mqtt_tls_cert) FROM stdin;
1	devices_au915	Frequency Plan AU915	1	3dd33931-1cf7-4a56-8479-e88afa94a9e5				\\x
\.


--
-- TOC entry 3778 (class 0 OID 17380)
-- Dependencies: 236
-- Data for Name: code_migration; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public.code_migration (id, applied_at) FROM stdin;
migrate_gw_stats	2026-05-01 15:01:53.809662+00
migrate_to_cluster_keys	2026-05-01 15:01:53.838145+00
\.


--
-- TOC entry 3773 (class 0 OID 16988)
-- Dependencies: 231
-- Data for Name: device; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public.device (dev_eui, created_at, updated_at, application_id, device_profile_id, name, description, last_seen_at, device_status_battery, device_status_margin, latitude, longitude, altitude, device_status_external_power_source, dr, variables, tags, dev_addr, app_s_key) FROM stdin;
\\x08fdbe4bc604e8f8	2026-05-17 14:44:05.641163+00	2026-05-17 14:44:05.641163+00	1	1ba78642-7e07-4f89-8dd9-4e2f7a025348	ESP32 RF95W (ABP)	ESP32 with RF95W (ABP)	\N	\N	\N	\N	\N	\N	f	\N			\\x00aa88ca	\\xfd91d55dce3af1023093e289a1d9f3df
\\xf38df5e5a31e63de	2026-05-17 14:45:29.062776+00	2026-05-17 14:45:29.062776+00	1	014c944b-cfa0-472d-94df-fd6c18843572	ESP32 RF95W (OTAA)	ESP32 with RF95W (OTAA)	\N	\N	\N	\N	\N	\N	f	\N			\\x00000000	\\x00000000000000000000000000000000
\.


--
-- TOC entry 3774 (class 0 OID 17011)
-- Dependencies: 232
-- Data for Name: device_keys; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public.device_keys (dev_eui, created_at, updated_at, nwk_key, join_nonce, app_key) FROM stdin;
\\xf38df5e5a31e63de	2026-05-17 14:45:37.322888+00	2026-05-17 14:45:37.322888+00	\\x6fc57c4cda46ddc502bcb7855e4e94ae	0	\\x00000000000000000000000000000000
\.


--
-- TOC entry 3777 (class 0 OID 17210)
-- Dependencies: 235
-- Data for Name: device_multicast_group; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public.device_multicast_group (dev_eui, multicast_group_id, created_at) FROM stdin;
\.


--
-- TOC entry 3772 (class 0 OID 16969)
-- Dependencies: 230
-- Data for Name: device_profile; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public.device_profile (device_profile_id, network_server_id, organization_id, created_at, updated_at, name, payload_codec, payload_encoder_script, payload_decoder_script, tags, uplink_interval) FROM stdin;
dbace6c1-ee3b-4b64-a737-499589bcad82	1	1	2026-05-10 15:49:27.072209+00	2026-05-10 15:49:27.072209+00	Devide Profile - AU915_0 - 1.0.3 - A (OTAA)					60000000000
edb8165c-2f2b-49ff-8dd9-448484c1f92a	1	1	2026-05-10 15:50:43.503973+00	2026-05-10 15:50:43.503973+00	Devide Profile - AU915_1 - 1.0.3 - A (OTAA)					60000000000
47dbd59c-dbeb-4341-a0ee-78ac23caa698	1	1	2026-05-10 15:51:16.571347+00	2026-05-10 15:51:16.571347+00	Devide Profile - AU915_0 - 1.0.3 - B (OTAA)					60000000000
d39827e9-1e0c-4f90-94c3-04df5fe12a25	1	1	2026-05-01 19:43:58.130383+00	2026-05-11 18:40:21.624335+00	Devide Profile - AU915_0 - 1.0.3 - A (ABP)					60000000000
1cf78205-847a-46f3-acef-8f55842431c9	1	1	2026-05-01 19:45:40.616376+00	2026-05-11 18:40:31.890518+00	Devide Profile - AU915_0 - 1.0.3 - B (ABP)					60000000000
098744b6-72ba-494e-b276-2a5b831abde5	1	1	2026-05-01 19:44:53.822344+00	2026-05-11 18:40:49.864038+00	Devide Profile - AU915_1 - 1.0.3 - A (ABP)					60000000000
1ba78642-7e07-4f89-8dd9-4e2f7a025348	1	1	2026-05-01 19:46:21.935149+00	2026-05-16 14:19:52.709972+00	Devide Profile - AU915_1 - 1.0.3 - B (ABP)					60000000000
014c944b-cfa0-472d-94df-fd6c18843572	1	1	2026-05-10 15:51:49.820815+00	2026-05-16 14:19:57.947821+00	Devide Profile - AU915_1 - 1.0.3 - B (OTAA)					60000000000
\.


--
-- TOC entry 3762 (class 0 OID 16831)
-- Dependencies: 220
-- Data for Name: gateway; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public.gateway (mac, created_at, updated_at, name, description, organization_id, ping, last_ping_id, last_ping_sent_at, network_server_id, gateway_profile_id, first_seen_at, last_seen_at, latitude, longitude, altitude, tags, metadata, service_profile_id) FROM stdin;
\\xb827ebfffe158993	2026-05-01 19:47:40.938468+00	2026-05-18 20:49:41.349693+00	002-gtw-radioenge-001	IP: 192.168.3.202 - Radioenge RPi3-RD43HATGPS (Multi Channel)	1	t	166711	2026-05-18 20:49:41.340655+00	1	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	\N	\N	51.482594	-0.007661	0		\N	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\\xb827ebfffef81e69	2026-05-01 19:48:08.11787+00	2026-05-18 20:49:42.361019+00	003-gtw-radioenge-002	IP: 192.168.3.203 - Radioenge RPi3-RD43HATGPS (Multi Channel)	1	t	166712	2026-05-18 20:49:42.358182+00	1	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	\N	\N	51.482594	-0.007661	0		\N	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\\xb827ebfffe78ffce	2026-05-01 19:48:38.200052+00	2026-05-18 20:49:43.370703+00	004-gtw-radioenge-003	IP: 192.168.3.204 - Radioenge RPi3-RD43HATGPS (Multi Channel)	1	t	166713	2026-05-18 20:49:43.367898+00	1	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	\N	\N	51.482594	-0.007661	0		\N	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\\xe45f01fffe10e12e	2026-05-01 19:49:17.460415+00	2026-05-18 20:49:44.380937+00	005-gtw-elecrow-001	IP: 192.168.3.205 - Elecrow RPi4-GPS (Multi Channel)	1	t	166714	2026-05-18 20:49:44.378228+00	1	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	\N	\N	51.482594	-0.007661	0		\N	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\\xa840411b7dcc4150	2026-05-01 19:49:45.273375+00	2026-05-18 20:49:45.390594+00	006-gtw-dragino_lg02-001	IP: 10.130.1.1 - Dragino LG02 (Dual Channel)	1	t	166715	2026-05-18 20:49:45.388019+00	1	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	\N	\N	51.482594	-0.007661	0		\N	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\\xb827ebfffea04db6	2026-05-01 19:47:14.924914+00	2026-05-18 20:49:46.409565+00	001-gtw-rak831-001	IP: 192.168.3.201 - RAK831 RPi3-GPS (Multi Channel)	1	t	166716	2026-05-18 20:49:46.407031+00	1	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	\N	\N	51.482594	-0.007661	0		\N	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\.


--
-- TOC entry 3766 (class 0 OID 16886)
-- Dependencies: 224
-- Data for Name: gateway_ping; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public.gateway_ping (id, created_at, gateway_mac, frequency, dr) FROM stdin;
1	2026-05-01 19:47:15.793383+00	\\xb827ebfffea04db6	916800000	5
2	2026-05-01 19:47:41.911562+00	\\xb827ebfffe158993	916800000	5
3	2026-05-01 19:48:09.034807+00	\\xb827ebfffef81e69	916800000	5
4	2026-05-01 19:48:39.15254+00	\\xb827ebfffe78ffce	916800000	5
5	2026-05-01 19:49:18.336448+00	\\xe45f01fffe10e12e	916800000	5
6	2026-05-01 19:49:45.444113+00	\\xa840411b7dcc4150	916800000	5
7	2026-05-01 20:47:16.569632+00	\\xb827ebfffea04db6	916800000	5
8	2026-05-01 20:47:42.670821+00	\\xb827ebfffe158993	916800000	5
9	2026-05-01 20:48:09.795148+00	\\xb827ebfffef81e69	916800000	5
10	2026-05-01 20:48:39.921593+00	\\xb827ebfffe78ffce	916800000	5
11	2026-05-01 20:49:19.078394+00	\\xe45f01fffe10e12e	916800000	5
12	2026-05-01 20:49:46.181809+00	\\xa840411b7dcc4150	916800000	5
13	2026-05-01 21:47:17.293135+00	\\xb827ebfffea04db6	916800000	5
14	2026-05-01 21:47:43.39913+00	\\xb827ebfffe158993	916800000	5
15	2026-05-01 21:48:10.538025+00	\\xb827ebfffef81e69	916800000	5
16	2026-05-01 21:48:40.651332+00	\\xb827ebfffe78ffce	916800000	5
17	2026-05-01 21:49:19.814701+00	\\xe45f01fffe10e12e	916800000	5
18	2026-05-01 21:49:46.916006+00	\\xa840411b7dcc4150	916800000	5
19	2026-05-01 22:47:17.867441+00	\\xb827ebfffea04db6	916800000	5
20	2026-05-01 22:47:44.008316+00	\\xb827ebfffe158993	916800000	5
21	2026-05-01 22:48:11.121645+00	\\xb827ebfffef81e69	916800000	5
22	2026-05-01 22:48:41.237226+00	\\xb827ebfffe78ffce	916800000	5
23	2026-05-01 22:49:20.462466+00	\\xe45f01fffe10e12e	916800000	5
24	2026-05-01 22:49:47.593544+00	\\xa840411b7dcc4150	916800000	5
25	2026-05-01 23:47:18.491851+00	\\xb827ebfffea04db6	916800000	5
26	2026-05-01 23:47:44.623859+00	\\xb827ebfffe158993	916800000	5
27	2026-05-01 23:48:11.737395+00	\\xb827ebfffef81e69	916800000	5
28	2026-05-01 23:48:41.867446+00	\\xb827ebfffe78ffce	916800000	5
29	2026-05-01 23:49:21.057795+00	\\xe45f01fffe10e12e	916800000	5
30	2026-05-01 23:49:48.162093+00	\\xa840411b7dcc4150	916800000	5
31	2026-05-02 00:47:19.339573+00	\\xb827ebfffea04db6	916800000	5
32	2026-05-02 00:47:45.440846+00	\\xb827ebfffe158993	916800000	5
33	2026-05-02 00:48:12.538888+00	\\xb827ebfffef81e69	916800000	5
34	2026-05-02 00:48:42.651831+00	\\xb827ebfffe78ffce	916800000	5
35	2026-05-02 00:49:21.814582+00	\\xe45f01fffe10e12e	916800000	5
36	2026-05-02 00:49:48.91358+00	\\xa840411b7dcc4150	916800000	5
37	2026-05-02 01:47:19.70486+00	\\xb827ebfffea04db6	916800000	5
38	2026-05-02 01:47:45.818246+00	\\xb827ebfffe158993	916800000	5
39	2026-05-02 01:48:12.925511+00	\\xb827ebfffef81e69	916800000	5
40	2026-05-02 01:48:43.061261+00	\\xb827ebfffe78ffce	916800000	5
41	2026-05-02 01:49:22.26866+00	\\xe45f01fffe10e12e	916800000	5
42	2026-05-02 01:49:49.372026+00	\\xa840411b7dcc4150	916800000	5
43	2026-05-02 02:47:20.175085+00	\\xb827ebfffea04db6	916800000	5
44	2026-05-02 02:47:46.318596+00	\\xb827ebfffe158993	916800000	5
45	2026-05-02 02:48:13.422118+00	\\xb827ebfffef81e69	916800000	5
46	2026-05-02 02:48:43.565664+00	\\xb827ebfffe78ffce	916800000	5
47	2026-05-02 02:49:22.724469+00	\\xe45f01fffe10e12e	916800000	5
48	2026-05-02 02:49:49.83144+00	\\xa840411b7dcc4150	916800000	5
49	2026-05-02 03:47:21.00167+00	\\xb827ebfffea04db6	916800000	5
50	2026-05-02 03:47:47.112893+00	\\xb827ebfffe158993	916800000	5
51	2026-05-02 03:48:14.251187+00	\\xb827ebfffef81e69	916800000	5
52	2026-05-02 03:48:44.367023+00	\\xb827ebfffe78ffce	916800000	5
53	2026-05-02 03:49:23.527046+00	\\xe45f01fffe10e12e	916800000	5
54	2026-05-02 03:49:50.62842+00	\\xa840411b7dcc4150	916800000	5
55	2026-05-02 04:47:21.584572+00	\\xb827ebfffea04db6	916800000	5
56	2026-05-02 04:47:47.680788+00	\\xb827ebfffe158993	916800000	5
57	2026-05-02 04:48:14.807956+00	\\xb827ebfffef81e69	916800000	5
58	2026-05-02 04:48:44.918776+00	\\xb827ebfffe78ffce	916800000	5
59	2026-05-02 04:49:24.069882+00	\\xe45f01fffe10e12e	916800000	5
60	2026-05-02 04:49:51.171687+00	\\xa840411b7dcc4150	916800000	5
61	2026-05-02 05:47:22.261281+00	\\xb827ebfffea04db6	916800000	5
62	2026-05-02 05:47:48.366437+00	\\xb827ebfffe158993	916800000	5
63	2026-05-02 05:48:15.486809+00	\\xb827ebfffef81e69	916800000	5
64	2026-05-02 05:48:45.596917+00	\\xb827ebfffe78ffce	916800000	5
65	2026-05-02 05:49:24.745232+00	\\xe45f01fffe10e12e	916800000	5
66	2026-05-02 05:49:51.857001+00	\\xa840411b7dcc4150	916800000	5
67	2026-05-02 06:47:22.839273+00	\\xb827ebfffea04db6	916800000	5
68	2026-05-02 06:47:48.9914+00	\\xb827ebfffe158993	916800000	5
69	2026-05-02 06:48:16.095733+00	\\xb827ebfffef81e69	916800000	5
70	2026-05-02 06:48:46.241167+00	\\xb827ebfffe78ffce	916800000	5
71	2026-05-02 06:49:25.427969+00	\\xe45f01fffe10e12e	916800000	5
72	2026-05-02 06:49:52.578837+00	\\xa840411b7dcc4150	916800000	5
73	2026-05-02 07:47:23.566665+00	\\xb827ebfffea04db6	916800000	5
74	2026-05-02 07:47:49.663859+00	\\xb827ebfffe158993	916800000	5
75	2026-05-02 07:48:16.799798+00	\\xb827ebfffef81e69	916800000	5
76	2026-05-02 07:48:46.914906+00	\\xb827ebfffe78ffce	916800000	5
77	2026-05-02 07:49:26.104025+00	\\xe45f01fffe10e12e	916800000	5
78	2026-05-02 07:49:53.216662+00	\\xa840411b7dcc4150	916800000	5
79	2026-05-02 08:47:24.139784+00	\\xb827ebfffea04db6	916800000	5
80	2026-05-02 08:47:50.263028+00	\\xb827ebfffe158993	916800000	5
81	2026-05-02 08:48:17.381752+00	\\xb827ebfffef81e69	916800000	5
82	2026-05-02 08:48:47.506301+00	\\xb827ebfffe78ffce	916800000	5
83	2026-05-02 08:49:26.66333+00	\\xe45f01fffe10e12e	916800000	5
84	2026-05-02 08:49:53.76935+00	\\xa840411b7dcc4150	916800000	5
85	2026-05-02 09:47:24.705796+00	\\xb827ebfffea04db6	916800000	5
86	2026-05-02 09:47:50.826318+00	\\xb827ebfffe158993	916800000	5
87	2026-05-02 09:48:17.929101+00	\\xb827ebfffef81e69	916800000	5
88	2026-05-02 09:48:48.075468+00	\\xb827ebfffe78ffce	916800000	5
89	2026-05-02 09:49:27.256352+00	\\xe45f01fffe10e12e	916800000	5
90	2026-05-02 09:49:54.353542+00	\\xa840411b7dcc4150	916800000	5
91	2026-05-02 10:47:25.237056+00	\\xb827ebfffea04db6	916800000	5
92	2026-05-02 10:47:51.347189+00	\\xb827ebfffe158993	916800000	5
93	2026-05-02 10:48:18.45361+00	\\xb827ebfffef81e69	916800000	5
94	2026-05-02 10:48:48.59664+00	\\xb827ebfffe78ffce	916800000	5
95	2026-05-02 10:49:27.757406+00	\\xe45f01fffe10e12e	916800000	5
96	2026-05-02 10:49:54.887647+00	\\xa840411b7dcc4150	916800000	5
97	2026-05-02 11:47:25.907762+00	\\xb827ebfffea04db6	916800000	5
98	2026-05-02 11:47:52.014227+00	\\xb827ebfffe158993	916800000	5
99	2026-05-02 11:48:19.115596+00	\\xb827ebfffef81e69	916800000	5
100	2026-05-02 11:48:49.243436+00	\\xb827ebfffe78ffce	916800000	5
101	2026-05-02 11:49:28.431742+00	\\xe45f01fffe10e12e	916800000	5
102	2026-05-02 11:49:55.556409+00	\\xa840411b7dcc4150	916800000	5
103	2026-05-02 12:47:26.692419+00	\\xb827ebfffea04db6	916800000	5
104	2026-05-02 12:47:52.810899+00	\\xb827ebfffe158993	916800000	5
105	2026-05-02 12:48:19.933974+00	\\xb827ebfffef81e69	916800000	5
106	2026-05-02 12:48:50.041702+00	\\xb827ebfffe78ffce	916800000	5
107	2026-05-02 12:49:29.206734+00	\\xe45f01fffe10e12e	916800000	5
108	2026-05-02 12:49:56.312174+00	\\xa840411b7dcc4150	916800000	5
109	2026-05-02 13:47:27.530633+00	\\xb827ebfffea04db6	916800000	5
110	2026-05-02 13:47:53.641541+00	\\xb827ebfffe158993	916800000	5
111	2026-05-02 13:48:20.743554+00	\\xb827ebfffef81e69	916800000	5
112	2026-05-02 13:48:50.868472+00	\\xb827ebfffe78ffce	916800000	5
113	2026-05-02 13:49:30.045884+00	\\xe45f01fffe10e12e	916800000	5
114	2026-05-02 13:49:57.174697+00	\\xa840411b7dcc4150	916800000	5
115	2026-05-02 14:47:28.219734+00	\\xb827ebfffea04db6	916800000	5
116	2026-05-02 14:47:54.39128+00	\\xb827ebfffe158993	916800000	5
117	2026-05-02 14:48:21.51431+00	\\xb827ebfffef81e69	916800000	5
118	2026-05-02 14:48:51.641782+00	\\xb827ebfffe78ffce	916800000	5
119	2026-05-02 14:49:30.809657+00	\\xe45f01fffe10e12e	916800000	5
120	2026-05-02 14:49:57.905745+00	\\xa840411b7dcc4150	916800000	5
121	2026-05-02 15:47:28.889514+00	\\xb827ebfffea04db6	916800000	5
122	2026-05-02 15:47:54.995596+00	\\xb827ebfffe158993	916800000	5
123	2026-05-02 15:48:22.131201+00	\\xb827ebfffef81e69	916800000	5
124	2026-05-02 15:48:52.252398+00	\\xb827ebfffe78ffce	916800000	5
125	2026-05-02 15:49:31.4275+00	\\xe45f01fffe10e12e	916800000	5
126	2026-05-02 15:49:58.529488+00	\\xa840411b7dcc4150	916800000	5
127	2026-05-02 16:47:29.450961+00	\\xb827ebfffea04db6	916800000	5
128	2026-05-02 16:47:55.555988+00	\\xb827ebfffe158993	916800000	5
129	2026-05-02 16:48:22.667226+00	\\xb827ebfffef81e69	916800000	5
130	2026-05-02 16:48:52.797791+00	\\xb827ebfffe78ffce	916800000	5
131	2026-05-02 16:49:31.972249+00	\\xe45f01fffe10e12e	916800000	5
132	2026-05-02 16:49:59.089861+00	\\xa840411b7dcc4150	916800000	5
133	2026-05-02 17:47:30.059714+00	\\xb827ebfffea04db6	916800000	5
134	2026-05-02 17:47:56.160183+00	\\xb827ebfffe158993	916800000	5
135	2026-05-02 17:48:23.282921+00	\\xb827ebfffef81e69	916800000	5
136	2026-05-02 17:48:53.409278+00	\\xb827ebfffe78ffce	916800000	5
137	2026-05-02 17:49:32.540775+00	\\xe45f01fffe10e12e	916800000	5
138	2026-05-02 17:49:59.65833+00	\\xa840411b7dcc4150	916800000	5
139	2026-05-02 18:47:30.735353+00	\\xb827ebfffea04db6	916800000	5
140	2026-05-02 18:47:56.843436+00	\\xb827ebfffe158993	916800000	5
141	2026-05-02 18:48:23.959705+00	\\xb827ebfffef81e69	916800000	5
142	2026-05-02 18:48:54.092825+00	\\xb827ebfffe78ffce	916800000	5
143	2026-05-02 18:49:33.272578+00	\\xe45f01fffe10e12e	916800000	5
144	2026-05-02 18:50:00.406231+00	\\xa840411b7dcc4150	916800000	5
145	2026-05-02 19:47:31.387435+00	\\xb827ebfffea04db6	916800000	5
146	2026-05-02 19:47:57.487454+00	\\xb827ebfffe158993	916800000	5
147	2026-05-02 19:48:24.596712+00	\\xb827ebfffef81e69	916800000	5
148	2026-05-02 19:48:54.73138+00	\\xb827ebfffe78ffce	916800000	5
149	2026-05-02 19:49:33.897418+00	\\xe45f01fffe10e12e	916800000	5
150	2026-05-02 19:50:01.030702+00	\\xa840411b7dcc4150	916800000	5
151	2026-05-02 20:47:31.988713+00	\\xb827ebfffea04db6	916800000	5
152	2026-05-02 20:47:58.087166+00	\\xb827ebfffe158993	916800000	5
153	2026-05-02 20:48:25.1932+00	\\xb827ebfffef81e69	916800000	5
154	2026-05-02 20:48:55.327219+00	\\xb827ebfffe78ffce	916800000	5
155	2026-05-02 20:49:34.494656+00	\\xe45f01fffe10e12e	916800000	5
156	2026-05-02 20:50:01.591454+00	\\xa840411b7dcc4150	916800000	5
157	2026-05-02 21:47:32.673451+00	\\xb827ebfffea04db6	916800000	5
158	2026-05-02 21:47:58.806618+00	\\xb827ebfffe158993	916800000	5
159	2026-05-02 21:48:25.917845+00	\\xb827ebfffef81e69	916800000	5
160	2026-05-02 21:48:56.053717+00	\\xb827ebfffe78ffce	916800000	5
161	2026-05-02 21:49:35.222991+00	\\xe45f01fffe10e12e	916800000	5
162	2026-05-02 21:50:02.377994+00	\\xa840411b7dcc4150	916800000	5
163	2026-05-02 22:47:33.585098+00	\\xb827ebfffea04db6	916800000	5
164	2026-05-02 22:47:59.679455+00	\\xb827ebfffe158993	916800000	5
165	2026-05-02 22:48:26.796221+00	\\xb827ebfffef81e69	916800000	5
166	2026-05-02 22:48:56.914587+00	\\xb827ebfffe78ffce	916800000	5
167	2026-05-02 22:49:36.097889+00	\\xe45f01fffe10e12e	916800000	5
168	2026-05-02 22:50:03.211542+00	\\xa840411b7dcc4150	916800000	5
169	2026-05-02 23:47:34.271257+00	\\xb827ebfffea04db6	916800000	5
170	2026-05-02 23:48:00.376954+00	\\xb827ebfffe158993	916800000	5
171	2026-05-02 23:48:27.464768+00	\\xb827ebfffef81e69	916800000	5
172	2026-05-02 23:48:57.569835+00	\\xb827ebfffe78ffce	916800000	5
173	2026-05-02 23:49:36.701671+00	\\xe45f01fffe10e12e	916800000	5
174	2026-05-02 23:50:03.809888+00	\\xa840411b7dcc4150	916800000	5
175	2026-05-03 00:47:34.825014+00	\\xb827ebfffea04db6	916800000	5
176	2026-05-03 00:48:00.943559+00	\\xb827ebfffe158993	916800000	5
177	2026-05-03 00:48:28.068701+00	\\xb827ebfffef81e69	916800000	5
178	2026-05-03 00:48:58.195126+00	\\xb827ebfffe78ffce	916800000	5
179	2026-05-03 00:49:37.374846+00	\\xe45f01fffe10e12e	916800000	5
180	2026-05-03 00:50:04.473617+00	\\xa840411b7dcc4150	916800000	5
181	2026-05-03 01:47:35.401734+00	\\xb827ebfffea04db6	916800000	5
182	2026-05-03 01:48:01.514738+00	\\xb827ebfffe158993	916800000	5
183	2026-05-03 01:48:28.622642+00	\\xb827ebfffef81e69	916800000	5
184	2026-05-03 01:48:58.736612+00	\\xb827ebfffe78ffce	916800000	5
185	2026-05-03 01:49:37.90921+00	\\xe45f01fffe10e12e	916800000	5
186	2026-05-03 01:50:05.020919+00	\\xa840411b7dcc4150	916800000	5
187	2026-05-03 02:47:36.026219+00	\\xb827ebfffea04db6	916800000	5
188	2026-05-03 02:48:02.13145+00	\\xb827ebfffe158993	916800000	5
189	2026-05-03 02:48:29.264027+00	\\xb827ebfffef81e69	916800000	5
190	2026-05-03 02:48:59.417067+00	\\xb827ebfffe78ffce	916800000	5
191	2026-05-03 02:49:38.600061+00	\\xe45f01fffe10e12e	916800000	5
192	2026-05-03 02:50:05.708202+00	\\xa840411b7dcc4150	916800000	5
193	2026-05-03 03:47:36.871319+00	\\xb827ebfffea04db6	916800000	5
194	2026-05-03 03:48:02.985035+00	\\xb827ebfffe158993	916800000	5
195	2026-05-03 03:48:30.087601+00	\\xb827ebfffef81e69	916800000	5
196	2026-05-03 03:49:00.218374+00	\\xb827ebfffe78ffce	916800000	5
197	2026-05-03 03:49:39.385493+00	\\xe45f01fffe10e12e	916800000	5
198	2026-05-03 03:50:06.493613+00	\\xa840411b7dcc4150	916800000	5
199	2026-05-03 04:47:37.482457+00	\\xb827ebfffea04db6	916800000	5
200	2026-05-03 04:48:03.583735+00	\\xb827ebfffe158993	916800000	5
201	2026-05-03 04:48:30.679321+00	\\xb827ebfffef81e69	916800000	5
202	2026-05-03 04:49:00.79579+00	\\xb827ebfffe78ffce	916800000	5
203	2026-05-03 04:49:39.962265+00	\\xe45f01fffe10e12e	916800000	5
204	2026-05-03 04:50:07.078803+00	\\xa840411b7dcc4150	916800000	5
205	2026-05-03 05:47:38.020417+00	\\xb827ebfffea04db6	916800000	5
206	2026-05-03 05:48:04.121091+00	\\xb827ebfffe158993	916800000	5
207	2026-05-03 05:48:31.233849+00	\\xb827ebfffef81e69	916800000	5
208	2026-05-03 05:49:01.459806+00	\\xb827ebfffe78ffce	916800000	5
209	2026-05-03 05:49:40.640076+00	\\xe45f01fffe10e12e	916800000	5
210	2026-05-03 05:50:07.753411+00	\\xa840411b7dcc4150	916800000	5
211	2026-05-03 06:47:38.491009+00	\\xb827ebfffea04db6	916800000	5
212	2026-05-03 06:48:04.630496+00	\\xb827ebfffe158993	916800000	5
213	2026-05-03 06:48:31.766109+00	\\xb827ebfffef81e69	916800000	5
214	2026-05-03 06:49:01.878258+00	\\xb827ebfffe78ffce	916800000	5
215	2026-05-03 06:49:41.081482+00	\\xe45f01fffe10e12e	916800000	5
216	2026-05-03 06:50:08.222301+00	\\xa840411b7dcc4150	916800000	5
217	2026-05-03 07:47:39.158799+00	\\xb827ebfffea04db6	916800000	5
218	2026-05-03 07:48:05.259599+00	\\xb827ebfffe158993	916800000	5
219	2026-05-03 07:48:32.363582+00	\\xb827ebfffef81e69	916800000	5
220	2026-05-03 07:49:02.506632+00	\\xb827ebfffe78ffce	916800000	5
221	2026-05-03 07:49:41.657054+00	\\xe45f01fffe10e12e	916800000	5
222	2026-05-03 07:50:08.758076+00	\\xa840411b7dcc4150	916800000	5
223	2026-05-03 08:47:39.794805+00	\\xb827ebfffea04db6	916800000	5
224	2026-05-03 08:48:05.909285+00	\\xb827ebfffe158993	916800000	5
225	2026-05-03 08:48:33.022048+00	\\xb827ebfffef81e69	916800000	5
226	2026-05-03 08:49:03.145516+00	\\xb827ebfffe78ffce	916800000	5
227	2026-05-03 08:49:42.30761+00	\\xe45f01fffe10e12e	916800000	5
228	2026-05-03 08:50:09.41496+00	\\xa840411b7dcc4150	916800000	5
229	2026-05-03 09:47:40.614439+00	\\xb827ebfffea04db6	916800000	5
230	2026-05-03 09:48:06.7162+00	\\xb827ebfffe158993	916800000	5
231	2026-05-03 09:48:33.822042+00	\\xb827ebfffef81e69	916800000	5
232	2026-05-03 09:49:03.94868+00	\\xb827ebfffe78ffce	916800000	5
233	2026-05-03 09:49:43.101704+00	\\xe45f01fffe10e12e	916800000	5
234	2026-05-03 09:50:10.203053+00	\\xa840411b7dcc4150	916800000	5
235	2026-05-03 10:47:41.083177+00	\\xb827ebfffea04db6	916800000	5
236	2026-05-03 10:48:07.194483+00	\\xb827ebfffe158993	916800000	5
237	2026-05-03 10:48:34.324227+00	\\xb827ebfffef81e69	916800000	5
238	2026-05-03 10:49:04.439604+00	\\xb827ebfffe78ffce	916800000	5
239	2026-05-03 10:49:43.60472+00	\\xe45f01fffe10e12e	916800000	5
240	2026-05-03 10:50:10.704881+00	\\xa840411b7dcc4150	916800000	5
241	2026-05-03 11:47:41.654811+00	\\xb827ebfffea04db6	916800000	5
242	2026-05-03 11:48:07.78048+00	\\xb827ebfffe158993	916800000	5
243	2026-05-03 11:48:34.888264+00	\\xb827ebfffef81e69	916800000	5
244	2026-05-03 11:49:05.012938+00	\\xb827ebfffe78ffce	916800000	5
245	2026-05-03 11:49:44.167125+00	\\xe45f01fffe10e12e	916800000	5
246	2026-05-03 11:50:11.282576+00	\\xa840411b7dcc4150	916800000	5
247	2026-05-03 12:47:42.470478+00	\\xb827ebfffea04db6	916800000	5
248	2026-05-03 12:48:08.577421+00	\\xb827ebfffe158993	916800000	5
249	2026-05-03 12:48:35.722696+00	\\xb827ebfffef81e69	916800000	5
250	2026-05-03 12:49:05.854045+00	\\xb827ebfffe78ffce	916800000	5
251	2026-05-03 12:49:45.040624+00	\\xe45f01fffe10e12e	916800000	5
252	2026-05-03 12:50:12.139576+00	\\xa840411b7dcc4150	916800000	5
253	2026-05-03 13:47:43.293697+00	\\xb827ebfffea04db6	916800000	5
254	2026-05-03 13:48:09.458259+00	\\xb827ebfffe158993	916800000	5
255	2026-05-03 13:48:36.581056+00	\\xb827ebfffef81e69	916800000	5
256	2026-05-03 13:49:06.695542+00	\\xb827ebfffe78ffce	916800000	5
257	2026-05-03 13:49:45.870124+00	\\xe45f01fffe10e12e	916800000	5
258	2026-05-03 13:50:12.971015+00	\\xa840411b7dcc4150	916800000	5
259	2026-05-03 14:47:44.064891+00	\\xb827ebfffea04db6	916800000	5
260	2026-05-03 14:48:10.164432+00	\\xb827ebfffe158993	916800000	5
261	2026-05-03 14:48:37.269079+00	\\xb827ebfffef81e69	916800000	5
262	2026-05-03 14:49:07.387195+00	\\xb827ebfffe78ffce	916800000	5
263	2026-05-03 14:49:46.572091+00	\\xe45f01fffe10e12e	916800000	5
264	2026-05-03 14:50:13.673037+00	\\xa840411b7dcc4150	916800000	5
265	2026-05-03 15:47:44.718429+00	\\xb827ebfffea04db6	916800000	5
266	2026-05-03 15:48:10.827563+00	\\xb827ebfffe158993	916800000	5
267	2026-05-03 15:48:37.931564+00	\\xb827ebfffef81e69	916800000	5
268	2026-05-03 15:49:08.07189+00	\\xb827ebfffe78ffce	916800000	5
269	2026-05-03 15:49:47.276336+00	\\xe45f01fffe10e12e	916800000	5
270	2026-05-03 15:50:14.398415+00	\\xa840411b7dcc4150	916800000	5
271	2026-05-03 16:47:45.296908+00	\\xb827ebfffea04db6	916800000	5
272	2026-05-03 16:48:11.414772+00	\\xb827ebfffe158993	916800000	5
273	2026-05-03 16:48:38.529591+00	\\xb827ebfffef81e69	916800000	5
274	2026-05-03 16:49:08.654627+00	\\xb827ebfffe78ffce	916800000	5
275	2026-05-03 16:49:47.811313+00	\\xe45f01fffe10e12e	916800000	5
276	2026-05-03 16:50:14.924901+00	\\xa840411b7dcc4150	916800000	5
277	2026-05-03 17:47:45.957125+00	\\xb827ebfffea04db6	916800000	5
278	2026-05-03 17:48:12.060031+00	\\xb827ebfffe158993	916800000	5
279	2026-05-03 17:48:39.156914+00	\\xb827ebfffef81e69	916800000	5
280	2026-05-03 17:49:09.299144+00	\\xb827ebfffe78ffce	916800000	5
281	2026-05-03 17:49:48.461979+00	\\xe45f01fffe10e12e	916800000	5
282	2026-05-03 17:50:15.565049+00	\\xa840411b7dcc4150	916800000	5
283	2026-05-03 18:47:46.813465+00	\\xb827ebfffea04db6	916800000	5
284	2026-05-03 18:48:12.933425+00	\\xb827ebfffe158993	916800000	5
285	2026-05-03 18:48:40.041811+00	\\xb827ebfffef81e69	916800000	5
286	2026-05-03 18:49:10.161084+00	\\xb827ebfffe78ffce	916800000	5
287	2026-05-03 18:49:49.31165+00	\\xe45f01fffe10e12e	916800000	5
288	2026-05-03 18:50:16.415476+00	\\xa840411b7dcc4150	916800000	5
289	2026-05-03 19:47:47.488546+00	\\xb827ebfffea04db6	916800000	5
290	2026-05-03 19:48:13.590183+00	\\xb827ebfffe158993	916800000	5
291	2026-05-03 19:48:40.692328+00	\\xb827ebfffef81e69	916800000	5
292	2026-05-03 19:49:10.824179+00	\\xb827ebfffe78ffce	916800000	5
293	2026-05-03 19:49:49.996289+00	\\xe45f01fffe10e12e	916800000	5
294	2026-05-03 19:50:17.094419+00	\\xa840411b7dcc4150	916800000	5
295	2026-05-03 20:47:48.058468+00	\\xb827ebfffea04db6	916800000	5
296	2026-05-03 20:48:14.199576+00	\\xb827ebfffe158993	916800000	5
297	2026-05-03 20:48:41.377031+00	\\xb827ebfffef81e69	916800000	5
298	2026-05-03 20:49:11.524459+00	\\xb827ebfffe78ffce	916800000	5
299	2026-05-03 20:49:50.696036+00	\\xe45f01fffe10e12e	916800000	5
300	2026-05-03 20:50:17.837617+00	\\xa840411b7dcc4150	916800000	5
301	2026-05-03 21:47:48.937459+00	\\xb827ebfffea04db6	916800000	5
302	2026-05-03 21:48:15.097818+00	\\xb827ebfffe158993	916800000	5
303	2026-05-03 21:48:42.208647+00	\\xb827ebfffef81e69	916800000	5
304	2026-05-03 21:49:12.375558+00	\\xb827ebfffe78ffce	916800000	5
305	2026-05-03 21:49:51.556269+00	\\xe45f01fffe10e12e	916800000	5
306	2026-05-03 21:50:18.678884+00	\\xa840411b7dcc4150	916800000	5
307	2026-05-03 22:47:49.813266+00	\\xb827ebfffea04db6	916800000	5
308	2026-05-03 22:48:15.919338+00	\\xb827ebfffe158993	916800000	5
309	2026-05-03 22:48:43.036943+00	\\xb827ebfffef81e69	916800000	5
310	2026-05-03 22:49:13.150353+00	\\xb827ebfffe78ffce	916800000	5
311	2026-05-03 22:49:52.317601+00	\\xe45f01fffe10e12e	916800000	5
312	2026-05-03 22:50:19.410697+00	\\xa840411b7dcc4150	916800000	5
313	2026-05-03 23:47:50.457999+00	\\xb827ebfffea04db6	916800000	5
314	2026-05-03 23:48:16.568882+00	\\xb827ebfffe158993	916800000	5
315	2026-05-03 23:48:43.665814+00	\\xb827ebfffef81e69	916800000	5
316	2026-05-03 23:49:13.785415+00	\\xb827ebfffe78ffce	916800000	5
317	2026-05-03 23:49:52.948571+00	\\xe45f01fffe10e12e	916800000	5
318	2026-05-03 23:50:20.066163+00	\\xa840411b7dcc4150	916800000	5
319	2026-05-04 00:47:51.351381+00	\\xb827ebfffea04db6	916800000	5
320	2026-05-04 00:48:17.467642+00	\\xb827ebfffe158993	916800000	5
321	2026-05-04 00:48:44.574763+00	\\xb827ebfffef81e69	916800000	5
322	2026-05-04 00:49:14.697291+00	\\xb827ebfffe78ffce	916800000	5
323	2026-05-04 00:49:53.843165+00	\\xe45f01fffe10e12e	916800000	5
324	2026-05-04 00:50:20.947339+00	\\xa840411b7dcc4150	916800000	5
325	2026-05-04 01:47:52.163332+00	\\xb827ebfffea04db6	916800000	5
326	2026-05-04 01:48:18.269916+00	\\xb827ebfffe158993	916800000	5
327	2026-05-04 01:48:45.39319+00	\\xb827ebfffef81e69	916800000	5
328	2026-05-04 01:49:15.520527+00	\\xb827ebfffe78ffce	916800000	5
329	2026-05-04 01:49:54.672278+00	\\xe45f01fffe10e12e	916800000	5
330	2026-05-04 01:50:21.776123+00	\\xa840411b7dcc4150	916800000	5
331	2026-05-04 02:47:52.76157+00	\\xb827ebfffea04db6	916800000	5
332	2026-05-04 02:48:18.865634+00	\\xb827ebfffe158993	916800000	5
333	2026-05-04 02:48:45.997346+00	\\xb827ebfffef81e69	916800000	5
334	2026-05-04 02:49:16.12203+00	\\xb827ebfffe78ffce	916800000	5
335	2026-05-04 02:49:55.353795+00	\\xe45f01fffe10e12e	916800000	5
336	2026-05-04 02:50:22.471587+00	\\xa840411b7dcc4150	916800000	5
337	2026-05-04 03:47:53.522959+00	\\xb827ebfffea04db6	916800000	5
338	2026-05-04 03:48:19.648623+00	\\xb827ebfffe158993	916800000	5
339	2026-05-04 03:48:46.784113+00	\\xb827ebfffef81e69	916800000	5
340	2026-05-04 03:49:16.900089+00	\\xb827ebfffe78ffce	916800000	5
341	2026-05-04 03:49:56.096306+00	\\xe45f01fffe10e12e	916800000	5
342	2026-05-04 03:50:23.21089+00	\\xa840411b7dcc4150	916800000	5
343	2026-05-04 04:47:54.257865+00	\\xb827ebfffea04db6	916800000	5
344	2026-05-04 04:48:20.361374+00	\\xb827ebfffe158993	916800000	5
345	2026-05-04 04:48:47.449251+00	\\xb827ebfffef81e69	916800000	5
346	2026-05-04 04:49:17.593688+00	\\xb827ebfffe78ffce	916800000	5
347	2026-05-04 04:49:56.745889+00	\\xe45f01fffe10e12e	916800000	5
348	2026-05-04 04:50:23.862032+00	\\xa840411b7dcc4150	916800000	5
349	2026-05-04 05:47:54.955322+00	\\xb827ebfffea04db6	916800000	5
350	2026-05-04 05:48:21.054879+00	\\xb827ebfffe158993	916800000	5
351	2026-05-04 05:48:48.165365+00	\\xb827ebfffef81e69	916800000	5
352	2026-05-04 05:49:18.291603+00	\\xb827ebfffe78ffce	916800000	5
353	2026-05-04 05:49:57.448016+00	\\xe45f01fffe10e12e	916800000	5
354	2026-05-04 05:50:24.575114+00	\\xa840411b7dcc4150	916800000	5
355	2026-05-04 06:47:55.796314+00	\\xb827ebfffea04db6	916800000	5
356	2026-05-04 06:48:21.91189+00	\\xb827ebfffe158993	916800000	5
357	2026-05-04 06:48:49.028795+00	\\xb827ebfffef81e69	916800000	5
358	2026-05-04 06:49:19.142748+00	\\xb827ebfffe78ffce	916800000	5
359	2026-05-04 06:49:58.318376+00	\\xe45f01fffe10e12e	916800000	5
360	2026-05-04 06:50:25.428145+00	\\xa840411b7dcc4150	916800000	5
361	2026-05-04 07:47:56.492812+00	\\xb827ebfffea04db6	916800000	5
362	2026-05-04 07:48:22.607869+00	\\xb827ebfffe158993	916800000	5
363	2026-05-04 07:48:49.71527+00	\\xb827ebfffef81e69	916800000	5
364	2026-05-04 07:49:19.852899+00	\\xb827ebfffe78ffce	916800000	5
365	2026-05-04 07:49:59.011732+00	\\xe45f01fffe10e12e	916800000	5
366	2026-05-04 07:50:26.142363+00	\\xa840411b7dcc4150	916800000	5
367	2026-05-04 08:47:57.152596+00	\\xb827ebfffea04db6	916800000	5
368	2026-05-04 08:48:23.269299+00	\\xb827ebfffe158993	916800000	5
369	2026-05-04 08:48:50.371127+00	\\xb827ebfffef81e69	916800000	5
370	2026-05-04 08:49:20.506674+00	\\xb827ebfffe78ffce	916800000	5
371	2026-05-04 08:49:59.655288+00	\\xe45f01fffe10e12e	916800000	5
372	2026-05-04 08:50:26.766212+00	\\xa840411b7dcc4150	916800000	5
373	2026-05-04 09:47:57.893374+00	\\xb827ebfffea04db6	916800000	5
374	2026-05-04 09:48:24.047477+00	\\xb827ebfffe158993	916800000	5
375	2026-05-04 09:48:51.163519+00	\\xb827ebfffef81e69	916800000	5
376	2026-05-04 09:49:21.289688+00	\\xb827ebfffe78ffce	916800000	5
377	2026-05-04 09:50:00.514837+00	\\xe45f01fffe10e12e	916800000	5
378	2026-05-04 09:50:27.628719+00	\\xa840411b7dcc4150	916800000	5
379	2026-05-04 10:47:58.771429+00	\\xb827ebfffea04db6	916800000	5
380	2026-05-04 10:48:24.876541+00	\\xb827ebfffe158993	916800000	5
381	2026-05-04 10:48:52.000797+00	\\xb827ebfffef81e69	916800000	5
382	2026-05-04 10:49:22.13151+00	\\xb827ebfffe78ffce	916800000	5
383	2026-05-04 10:50:01.28155+00	\\xe45f01fffe10e12e	916800000	5
384	2026-05-04 10:50:28.379721+00	\\xa840411b7dcc4150	916800000	5
385	2026-05-04 11:47:58.973958+00	\\xb827ebfffea04db6	916800000	5
386	2026-05-04 11:48:25.101904+00	\\xb827ebfffe158993	916800000	5
387	2026-05-04 11:48:52.209306+00	\\xb827ebfffef81e69	916800000	5
388	2026-05-04 11:49:22.348741+00	\\xb827ebfffe78ffce	916800000	5
389	2026-05-04 11:50:01.52426+00	\\xe45f01fffe10e12e	916800000	5
390	2026-05-04 11:50:28.642575+00	\\xa840411b7dcc4150	916800000	5
391	2026-05-04 12:47:59.718546+00	\\xb827ebfffea04db6	916800000	5
392	2026-05-04 12:48:25.825429+00	\\xb827ebfffe158993	916800000	5
393	2026-05-04 12:48:52.958911+00	\\xb827ebfffef81e69	916800000	5
394	2026-05-04 12:49:23.096297+00	\\xb827ebfffe78ffce	916800000	5
395	2026-05-04 12:50:02.289796+00	\\xe45f01fffe10e12e	916800000	5
396	2026-05-04 12:50:29.403833+00	\\xa840411b7dcc4150	916800000	5
397	2026-05-04 13:48:00.691759+00	\\xb827ebfffea04db6	916800000	5
398	2026-05-04 13:48:26.822507+00	\\xb827ebfffe158993	916800000	5
399	2026-05-04 13:48:53.951752+00	\\xb827ebfffef81e69	916800000	5
400	2026-05-04 13:49:24.066878+00	\\xb827ebfffe78ffce	916800000	5
401	2026-05-04 13:50:03.232597+00	\\xe45f01fffe10e12e	916800000	5
402	2026-05-04 13:50:30.345225+00	\\xa840411b7dcc4150	916800000	5
403	2026-05-04 14:48:01.541069+00	\\xb827ebfffea04db6	916800000	5
404	2026-05-04 14:48:27.643221+00	\\xb827ebfffe158993	916800000	5
405	2026-05-04 14:48:54.747696+00	\\xb827ebfffef81e69	916800000	5
406	2026-05-04 14:49:24.916563+00	\\xb827ebfffe78ffce	916800000	5
407	2026-05-04 14:50:04.085455+00	\\xe45f01fffe10e12e	916800000	5
408	2026-05-04 14:50:31.20634+00	\\xa840411b7dcc4150	916800000	5
409	2026-05-04 15:48:02.392178+00	\\xb827ebfffea04db6	916800000	5
410	2026-05-04 15:48:28.492178+00	\\xb827ebfffe158993	916800000	5
411	2026-05-04 15:48:55.627763+00	\\xb827ebfffef81e69	916800000	5
412	2026-05-04 15:49:25.783363+00	\\xb827ebfffe78ffce	916800000	5
413	2026-05-04 15:50:04.939176+00	\\xe45f01fffe10e12e	916800000	5
414	2026-05-04 15:50:32.084263+00	\\xa840411b7dcc4150	916800000	5
415	2026-05-04 16:48:02.984148+00	\\xb827ebfffea04db6	916800000	5
416	2026-05-04 16:48:29.109928+00	\\xb827ebfffe158993	916800000	5
417	2026-05-04 16:48:56.223323+00	\\xb827ebfffef81e69	916800000	5
418	2026-05-04 16:49:26.348083+00	\\xb827ebfffe78ffce	916800000	5
419	2026-05-04 16:50:05.499186+00	\\xe45f01fffe10e12e	916800000	5
420	2026-05-04 16:50:32.614317+00	\\xa840411b7dcc4150	916800000	5
421	2026-05-04 17:48:03.063377+00	\\xb827ebfffea04db6	916800000	5
422	2026-05-04 17:48:29.185754+00	\\xb827ebfffe158993	916800000	5
423	2026-05-04 17:48:56.279258+00	\\xb827ebfffef81e69	916800000	5
424	2026-05-04 17:49:26.406619+00	\\xb827ebfffe78ffce	916800000	5
425	2026-05-04 17:50:05.554092+00	\\xe45f01fffe10e12e	916800000	5
426	2026-05-04 17:50:32.675924+00	\\xa840411b7dcc4150	916800000	5
427	2026-05-04 18:48:03.882074+00	\\xb827ebfffea04db6	916800000	5
428	2026-05-04 18:48:29.978485+00	\\xb827ebfffe158993	916800000	5
429	2026-05-04 18:48:57.100133+00	\\xb827ebfffef81e69	916800000	5
430	2026-05-04 18:49:27.229986+00	\\xb827ebfffe78ffce	916800000	5
431	2026-05-04 18:50:06.406682+00	\\xe45f01fffe10e12e	916800000	5
432	2026-05-04 18:50:33.509584+00	\\xa840411b7dcc4150	916800000	5
433	2026-05-04 19:48:04.346152+00	\\xb827ebfffea04db6	916800000	5
434	2026-05-04 19:48:30.438574+00	\\xb827ebfffe158993	916800000	5
435	2026-05-04 19:48:57.535724+00	\\xb827ebfffef81e69	916800000	5
436	2026-05-04 19:49:27.650665+00	\\xb827ebfffe78ffce	916800000	5
437	2026-05-04 19:50:06.825847+00	\\xe45f01fffe10e12e	916800000	5
438	2026-05-04 19:50:33.95064+00	\\xa840411b7dcc4150	916800000	5
439	2026-05-04 20:48:05.057145+00	\\xb827ebfffea04db6	916800000	5
440	2026-05-04 20:48:31.172461+00	\\xb827ebfffe158993	916800000	5
441	2026-05-04 20:48:58.325593+00	\\xb827ebfffef81e69	916800000	5
442	2026-05-04 20:49:28.438674+00	\\xb827ebfffe78ffce	916800000	5
443	2026-05-04 20:50:07.583458+00	\\xe45f01fffe10e12e	916800000	5
444	2026-05-04 20:50:34.690251+00	\\xa840411b7dcc4150	916800000	5
445	2026-05-04 21:48:05.072496+00	\\xb827ebfffea04db6	916800000	5
446	2026-05-04 21:48:32.168004+00	\\xb827ebfffe158993	916800000	5
447	2026-05-04 21:48:59.269392+00	\\xb827ebfffef81e69	916800000	5
448	2026-05-04 21:49:29.385478+00	\\xb827ebfffe78ffce	916800000	5
449	2026-05-04 21:50:08.528599+00	\\xe45f01fffe10e12e	916800000	5
450	2026-05-04 21:50:35.637034+00	\\xa840411b7dcc4150	916800000	5
451	2026-05-04 22:48:05.132955+00	\\xb827ebfffea04db6	916800000	5
452	2026-05-04 22:48:32.229788+00	\\xb827ebfffe158993	916800000	5
453	2026-05-04 22:48:59.335235+00	\\xb827ebfffef81e69	916800000	5
454	2026-05-04 22:49:29.452523+00	\\xb827ebfffe78ffce	916800000	5
455	2026-05-04 22:50:08.605786+00	\\xe45f01fffe10e12e	916800000	5
456	2026-05-04 22:50:35.714807+00	\\xa840411b7dcc4150	916800000	5
457	2026-05-04 23:48:06.079789+00	\\xb827ebfffea04db6	916800000	5
458	2026-05-04 23:48:33.225073+00	\\xb827ebfffe158993	916800000	5
459	2026-05-04 23:48:59.341814+00	\\xb827ebfffef81e69	916800000	5
460	2026-05-04 23:49:29.461515+00	\\xb827ebfffe78ffce	916800000	5
461	2026-05-04 23:50:08.666176+00	\\xe45f01fffe10e12e	916800000	5
462	2026-05-04 23:50:35.800788+00	\\xa840411b7dcc4150	916800000	5
463	2026-05-05 00:48:07.056904+00	\\xb827ebfffea04db6	916800000	5
464	2026-05-05 00:48:34.162891+00	\\xb827ebfffe158993	916800000	5
465	2026-05-05 00:49:00.255354+00	\\xb827ebfffef81e69	916800000	5
466	2026-05-05 00:49:30.398318+00	\\xb827ebfffe78ffce	916800000	5
467	2026-05-05 00:50:09.640042+00	\\xe45f01fffe10e12e	916800000	5
468	2026-05-05 00:50:36.785362+00	\\xa840411b7dcc4150	916800000	5
469	2026-05-05 01:48:07.891103+00	\\xb827ebfffea04db6	916800000	5
470	2026-05-05 01:48:35.004555+00	\\xb827ebfffe158993	916800000	5
471	2026-05-05 01:49:01.115515+00	\\xb827ebfffef81e69	916800000	5
472	2026-05-05 01:49:31.305288+00	\\xb827ebfffe78ffce	916800000	5
473	2026-05-05 01:50:10.470317+00	\\xe45f01fffe10e12e	916800000	5
474	2026-05-05 01:50:37.572489+00	\\xa840411b7dcc4150	916800000	5
475	2026-05-05 02:48:07.97997+00	\\xb827ebfffea04db6	916800000	5
476	2026-05-05 02:48:35.086972+00	\\xb827ebfffe158993	916800000	5
477	2026-05-05 02:49:01.185559+00	\\xb827ebfffef81e69	916800000	5
478	2026-05-05 02:49:32.305682+00	\\xb827ebfffe78ffce	916800000	5
479	2026-05-05 02:50:11.467673+00	\\xe45f01fffe10e12e	916800000	5
480	2026-05-05 02:50:38.568657+00	\\xa840411b7dcc4150	916800000	5
481	2026-05-05 03:48:08.943551+00	\\xb827ebfffea04db6	916800000	5
482	2026-05-05 03:48:36.070955+00	\\xb827ebfffe158993	916800000	5
483	2026-05-05 03:49:02.173807+00	\\xb827ebfffef81e69	916800000	5
484	2026-05-05 03:49:32.342779+00	\\xb827ebfffe78ffce	916800000	5
485	2026-05-05 03:50:11.482819+00	\\xe45f01fffe10e12e	916800000	5
486	2026-05-05 03:50:38.665821+00	\\xa840411b7dcc4150	916800000	5
487	2026-05-05 04:48:09.825612+00	\\xb827ebfffea04db6	916800000	5
488	2026-05-05 04:48:36.969226+00	\\xb827ebfffe158993	916800000	5
489	2026-05-05 04:49:03.07943+00	\\xb827ebfffef81e69	916800000	5
490	2026-05-05 04:49:33.224165+00	\\xb827ebfffe78ffce	916800000	5
491	2026-05-05 04:50:12.392665+00	\\xe45f01fffe10e12e	916800000	5
492	2026-05-05 04:50:39.514551+00	\\xa840411b7dcc4150	916800000	5
493	2026-05-05 05:48:09.99416+00	\\xb827ebfffea04db6	916800000	5
494	2026-05-05 05:48:37.095439+00	\\xb827ebfffe158993	916800000	5
495	2026-05-05 05:49:03.185871+00	\\xb827ebfffef81e69	916800000	5
496	2026-05-05 05:49:33.294988+00	\\xb827ebfffe78ffce	916800000	5
497	2026-05-05 05:50:12.537852+00	\\xe45f01fffe10e12e	916800000	5
498	2026-05-05 05:50:39.670913+00	\\xa840411b7dcc4150	916800000	5
499	2026-05-05 06:48:10.80547+00	\\xb827ebfffea04db6	916800000	5
500	2026-05-05 06:48:37.922324+00	\\xb827ebfffe158993	916800000	5
501	2026-05-05 06:49:04.045477+00	\\xb827ebfffef81e69	916800000	5
502	2026-05-05 06:49:34.226656+00	\\xb827ebfffe78ffce	916800000	5
503	2026-05-05 06:50:13.396948+00	\\xe45f01fffe10e12e	916800000	5
504	2026-05-05 06:50:40.501086+00	\\xa840411b7dcc4150	916800000	5
505	2026-05-05 07:48:10.898066+00	\\xb827ebfffea04db6	916800000	5
506	2026-05-05 07:48:38.003032+00	\\xb827ebfffe158993	916800000	5
507	2026-05-05 07:49:04.111334+00	\\xb827ebfffef81e69	916800000	5
508	2026-05-05 07:49:35.234973+00	\\xb827ebfffe78ffce	916800000	5
509	2026-05-05 07:50:14.387403+00	\\xe45f01fffe10e12e	916800000	5
510	2026-05-05 07:50:41.49665+00	\\xa840411b7dcc4150	916800000	5
511	2026-05-05 08:48:11.834812+00	\\xb827ebfffea04db6	916800000	5
512	2026-05-05 08:48:38.92731+00	\\xb827ebfffe158993	916800000	5
513	2026-05-05 08:49:05.01146+00	\\xb827ebfffef81e69	916800000	5
514	2026-05-05 08:49:36.112948+00	\\xb827ebfffe78ffce	916800000	5
515	2026-05-05 08:50:15.25007+00	\\xe45f01fffe10e12e	916800000	5
516	2026-05-05 08:50:42.35469+00	\\xa840411b7dcc4150	916800000	5
517	2026-05-05 09:48:12.637645+00	\\xb827ebfffea04db6	916800000	5
518	2026-05-05 09:48:39.734173+00	\\xb827ebfffe158993	916800000	5
519	2026-05-05 09:49:05.917371+00	\\xb827ebfffef81e69	916800000	5
520	2026-05-05 09:49:37.038747+00	\\xb827ebfffe78ffce	916800000	5
521	2026-05-05 09:50:16.23628+00	\\xe45f01fffe10e12e	916800000	5
522	2026-05-05 09:50:43.350346+00	\\xa840411b7dcc4150	916800000	5
523	2026-05-05 10:48:12.902681+00	\\xb827ebfffea04db6	916800000	5
524	2026-05-05 10:48:40.003003+00	\\xb827ebfffe158993	916800000	5
525	2026-05-05 10:49:06.102419+00	\\xb827ebfffef81e69	916800000	5
526	2026-05-05 10:49:37.227086+00	\\xb827ebfffe78ffce	916800000	5
527	2026-05-05 10:50:16.379104+00	\\xe45f01fffe10e12e	916800000	5
528	2026-05-05 10:50:43.542117+00	\\xa840411b7dcc4150	916800000	5
529	2026-05-05 11:48:12.918815+00	\\xb827ebfffea04db6	916800000	5
530	2026-05-05 11:48:40.023283+00	\\xb827ebfffe158993	916800000	5
531	2026-05-05 11:49:06.150024+00	\\xb827ebfffef81e69	916800000	5
532	2026-05-05 11:49:37.345878+00	\\xb827ebfffe78ffce	916800000	5
533	2026-05-05 11:50:16.506627+00	\\xe45f01fffe10e12e	916800000	5
534	2026-05-05 11:50:43.634156+00	\\xa840411b7dcc4150	916800000	5
535	2026-05-05 12:48:13.15692+00	\\xb827ebfffea04db6	916800000	5
536	2026-05-05 12:48:40.258444+00	\\xb827ebfffe158993	916800000	5
537	2026-05-05 12:49:06.360287+00	\\xb827ebfffef81e69	916800000	5
538	2026-05-05 12:49:37.486868+00	\\xb827ebfffe78ffce	916800000	5
539	2026-05-05 12:50:16.63683+00	\\xe45f01fffe10e12e	916800000	5
540	2026-05-05 12:50:43.742401+00	\\xa840411b7dcc4150	916800000	5
541	2026-05-05 13:48:14.12027+00	\\xb827ebfffea04db6	916800000	5
542	2026-05-05 13:48:41.225339+00	\\xb827ebfffe158993	916800000	5
543	2026-05-05 13:49:07.333966+00	\\xb827ebfffef81e69	916800000	5
544	2026-05-05 13:49:38.456052+00	\\xb827ebfffe78ffce	916800000	5
545	2026-05-05 13:50:17.611701+00	\\xe45f01fffe10e12e	916800000	5
546	2026-05-05 13:50:44.738806+00	\\xa840411b7dcc4150	916800000	5
547	2026-05-05 14:48:14.136922+00	\\xb827ebfffea04db6	916800000	5
548	2026-05-05 14:48:41.256687+00	\\xb827ebfffe158993	916800000	5
549	2026-05-05 14:49:07.369349+00	\\xb827ebfffef81e69	916800000	5
550	2026-05-05 14:49:38.515476+00	\\xb827ebfffe78ffce	916800000	5
551	2026-05-05 14:50:17.714977+00	\\xe45f01fffe10e12e	916800000	5
552	2026-05-05 14:50:44.870149+00	\\xa840411b7dcc4150	916800000	5
553	2026-05-05 15:48:14.23552+00	\\xb827ebfffea04db6	916800000	5
554	2026-05-05 15:48:41.334641+00	\\xb827ebfffe158993	916800000	5
555	2026-05-05 15:49:07.494458+00	\\xb827ebfffef81e69	916800000	5
556	2026-05-05 15:49:38.676179+00	\\xb827ebfffe78ffce	916800000	5
557	2026-05-05 15:50:17.884615+00	\\xe45f01fffe10e12e	916800000	5
558	2026-05-05 15:50:44.996059+00	\\xa840411b7dcc4150	916800000	5
559	2026-05-05 16:48:14.42678+00	\\xb827ebfffea04db6	916800000	5
560	2026-05-05 16:48:41.525645+00	\\xb827ebfffe158993	916800000	5
561	2026-05-05 16:49:07.620003+00	\\xb827ebfffef81e69	916800000	5
562	2026-05-05 16:49:38.743711+00	\\xb827ebfffe78ffce	916800000	5
563	2026-05-05 16:50:18.894351+00	\\xe45f01fffe10e12e	916800000	5
564	2026-05-05 16:50:45.036109+00	\\xa840411b7dcc4150	916800000	5
565	2026-05-05 17:48:15.276439+00	\\xb827ebfffea04db6	916800000	5
566	2026-05-05 17:48:42.392849+00	\\xb827ebfffe158993	916800000	5
567	2026-05-05 17:49:08.497227+00	\\xb827ebfffef81e69	916800000	5
568	2026-05-05 17:49:39.619454+00	\\xb827ebfffe78ffce	916800000	5
569	2026-05-05 17:50:19.779332+00	\\xe45f01fffe10e12e	916800000	5
570	2026-05-05 17:50:45.877822+00	\\xa840411b7dcc4150	916800000	5
571	2026-05-05 18:48:16.185132+00	\\xb827ebfffea04db6	916800000	5
572	2026-05-05 18:48:43.292811+00	\\xb827ebfffe158993	916800000	5
573	2026-05-05 18:49:09.393205+00	\\xb827ebfffef81e69	916800000	5
574	2026-05-05 18:49:40.516232+00	\\xb827ebfffe78ffce	916800000	5
575	2026-05-05 18:50:20.688436+00	\\xe45f01fffe10e12e	916800000	5
576	2026-05-05 18:50:46.869238+00	\\xa840411b7dcc4150	916800000	5
577	2026-05-05 19:48:16.204041+00	\\xb827ebfffea04db6	916800000	5
578	2026-05-05 19:48:43.310325+00	\\xb827ebfffe158993	916800000	5
579	2026-05-05 19:49:09.450804+00	\\xb827ebfffef81e69	916800000	5
580	2026-05-05 19:49:40.56848+00	\\xb827ebfffe78ffce	916800000	5
581	2026-05-05 19:50:20.789096+00	\\xe45f01fffe10e12e	916800000	5
582	2026-05-05 19:50:46.923144+00	\\xa840411b7dcc4150	916800000	5
583	2026-05-05 20:48:17.093582+00	\\xb827ebfffea04db6	916800000	5
584	2026-05-05 20:48:44.236395+00	\\xb827ebfffe158993	916800000	5
585	2026-05-05 20:49:10.341582+00	\\xb827ebfffef81e69	916800000	5
586	2026-05-05 20:49:41.521678+00	\\xb827ebfffe78ffce	916800000	5
587	2026-05-05 20:50:21.741376+00	\\xe45f01fffe10e12e	916800000	5
588	2026-05-05 20:50:47.886017+00	\\xa840411b7dcc4150	916800000	5
589	2026-05-05 21:48:17.234344+00	\\xb827ebfffea04db6	916800000	5
590	2026-05-05 21:48:44.373053+00	\\xb827ebfffe158993	916800000	5
591	2026-05-05 21:49:10.468831+00	\\xb827ebfffef81e69	916800000	5
592	2026-05-05 21:49:41.584076+00	\\xb827ebfffe78ffce	916800000	5
593	2026-05-05 21:50:22.745947+00	\\xe45f01fffe10e12e	916800000	5
594	2026-05-05 21:50:48.865095+00	\\xa840411b7dcc4150	916800000	5
595	2026-05-05 22:48:17.37404+00	\\xb827ebfffea04db6	916800000	5
596	2026-05-05 22:48:44.477307+00	\\xb827ebfffe158993	916800000	5
597	2026-05-05 22:49:10.573438+00	\\xb827ebfffef81e69	916800000	5
598	2026-05-05 22:49:41.691657+00	\\xb827ebfffe78ffce	916800000	5
599	2026-05-05 22:50:22.857104+00	\\xe45f01fffe10e12e	916800000	5
600	2026-05-05 22:50:48.948649+00	\\xa840411b7dcc4150	916800000	5
601	2026-05-05 23:48:18.25043+00	\\xb827ebfffea04db6	916800000	5
602	2026-05-05 23:48:45.36545+00	\\xb827ebfffe158993	916800000	5
603	2026-05-05 23:49:11.469791+00	\\xb827ebfffef81e69	916800000	5
604	2026-05-05 23:49:42.584639+00	\\xb827ebfffe78ffce	916800000	5
605	2026-05-05 23:50:23.743831+00	\\xe45f01fffe10e12e	916800000	5
606	2026-05-05 23:50:49.912878+00	\\xa840411b7dcc4150	916800000	5
607	2026-05-06 00:48:18.284425+00	\\xb827ebfffea04db6	916800000	5
608	2026-05-06 00:48:45.410961+00	\\xb827ebfffe158993	916800000	5
609	2026-05-06 00:49:11.539595+00	\\xb827ebfffef81e69	916800000	5
610	2026-05-06 00:49:42.696438+00	\\xb827ebfffe78ffce	916800000	5
611	2026-05-06 00:50:23.881561+00	\\xe45f01fffe10e12e	916800000	5
612	2026-05-06 00:50:50.001655+00	\\xa840411b7dcc4150	916800000	5
613	2026-05-06 01:48:18.321691+00	\\xb827ebfffea04db6	916800000	5
614	2026-05-06 01:48:45.547545+00	\\xb827ebfffe158993	916800000	5
615	2026-05-06 01:49:11.679524+00	\\xb827ebfffef81e69	916800000	5
616	2026-05-06 01:49:42.865734+00	\\xb827ebfffe78ffce	916800000	5
617	2026-05-06 01:50:24.039907+00	\\xe45f01fffe10e12e	916800000	5
618	2026-05-06 01:50:50.167782+00	\\xa840411b7dcc4150	916800000	5
619	2026-05-06 02:48:18.660359+00	\\xb827ebfffea04db6	916800000	5
620	2026-05-06 02:48:45.781471+00	\\xb827ebfffe158993	916800000	5
621	2026-05-06 02:49:11.887813+00	\\xb827ebfffef81e69	916800000	5
622	2026-05-06 02:49:43.010631+00	\\xb827ebfffe78ffce	916800000	5
623	2026-05-06 02:50:24.197677+00	\\xe45f01fffe10e12e	916800000	5
624	2026-05-06 02:50:50.307787+00	\\xa840411b7dcc4150	916800000	5
625	2026-05-06 03:48:19.60451+00	\\xb827ebfffea04db6	916800000	5
626	2026-05-06 03:48:46.702041+00	\\xb827ebfffe158993	916800000	5
627	2026-05-06 03:49:12.802054+00	\\xb827ebfffef81e69	916800000	5
628	2026-05-06 03:49:43.917281+00	\\xb827ebfffe78ffce	916800000	5
629	2026-05-06 03:50:25.086863+00	\\xe45f01fffe10e12e	916800000	5
630	2026-05-06 03:50:51.185854+00	\\xa840411b7dcc4150	916800000	5
631	2026-05-06 04:48:20.549208+00	\\xb827ebfffea04db6	916800000	5
632	2026-05-06 04:48:47.649357+00	\\xb827ebfffe158993	916800000	5
633	2026-05-06 04:49:13.754753+00	\\xb827ebfffef81e69	916800000	5
634	2026-05-06 04:49:43.951521+00	\\xb827ebfffe78ffce	916800000	5
635	2026-05-06 04:50:25.136037+00	\\xe45f01fffe10e12e	916800000	5
636	2026-05-06 04:50:51.253334+00	\\xa840411b7dcc4150	916800000	5
637	2026-05-06 05:48:20.63134+00	\\xb827ebfffea04db6	916800000	5
638	2026-05-06 05:48:47.774901+00	\\xb827ebfffe158993	916800000	5
639	2026-05-06 05:49:13.874884+00	\\xb827ebfffef81e69	916800000	5
640	2026-05-06 05:49:44.002587+00	\\xb827ebfffe78ffce	916800000	5
641	2026-05-06 05:50:25.1932+00	\\xe45f01fffe10e12e	916800000	5
642	2026-05-06 05:50:51.292123+00	\\xa840411b7dcc4150	916800000	5
643	2026-05-06 06:48:20.845371+00	\\xb827ebfffea04db6	916800000	5
644	2026-05-06 06:48:48.058321+00	\\xb827ebfffe158993	916800000	5
645	2026-05-06 06:49:14.227623+00	\\xb827ebfffef81e69	916800000	5
646	2026-05-06 06:49:44.352761+00	\\xb827ebfffe78ffce	916800000	5
647	2026-05-06 06:50:25.521756+00	\\xe45f01fffe10e12e	916800000	5
648	2026-05-06 06:50:51.620732+00	\\xa840411b7dcc4150	916800000	5
649	2026-05-06 07:48:21.740592+00	\\xb827ebfffea04db6	916800000	5
650	2026-05-06 07:48:48.845673+00	\\xb827ebfffe158993	916800000	5
651	2026-05-06 07:49:14.946263+00	\\xb827ebfffef81e69	916800000	5
652	2026-05-06 07:49:45.10377+00	\\xb827ebfffe78ffce	916800000	5
653	2026-05-06 07:50:26.262615+00	\\xe45f01fffe10e12e	916800000	5
654	2026-05-06 07:50:52.366169+00	\\xa840411b7dcc4150	916800000	5
655	2026-05-06 08:48:22.533581+00	\\xb827ebfffea04db6	916800000	5
656	2026-05-06 08:48:49.707004+00	\\xb827ebfffe158993	916800000	5
657	2026-05-06 08:49:15.79595+00	\\xb827ebfffef81e69	916800000	5
658	2026-05-06 08:49:45.893369+00	\\xb827ebfffe78ffce	916800000	5
659	2026-05-06 08:50:27.017108+00	\\xe45f01fffe10e12e	916800000	5
660	2026-05-06 08:50:53.102227+00	\\xa840411b7dcc4150	916800000	5
661	2026-05-06 09:48:23.234867+00	\\xb827ebfffea04db6	916800000	5
662	2026-05-06 09:48:50.336149+00	\\xb827ebfffe158993	916800000	5
663	2026-05-06 09:49:16.452045+00	\\xb827ebfffef81e69	916800000	5
664	2026-05-06 09:49:46.568183+00	\\xb827ebfffe78ffce	916800000	5
665	2026-05-06 09:50:27.726631+00	\\xe45f01fffe10e12e	916800000	5
666	2026-05-06 09:50:53.946895+00	\\xa840411b7dcc4150	916800000	5
667	2026-05-06 10:48:23.299527+00	\\xb827ebfffea04db6	916800000	5
668	2026-05-06 10:48:50.42323+00	\\xb827ebfffe158993	916800000	5
669	2026-05-06 10:49:16.561849+00	\\xb827ebfffef81e69	916800000	5
670	2026-05-06 10:49:46.703765+00	\\xb827ebfffe78ffce	916800000	5
671	2026-05-06 10:50:27.894171+00	\\xe45f01fffe10e12e	916800000	5
672	2026-05-06 10:50:54.011417+00	\\xa840411b7dcc4150	916800000	5
673	2026-05-06 11:48:23.372747+00	\\xb827ebfffea04db6	916800000	5
674	2026-05-06 11:48:50.502191+00	\\xb827ebfffe158993	916800000	5
675	2026-05-06 11:49:16.65632+00	\\xb827ebfffef81e69	916800000	5
676	2026-05-06 11:49:46.824158+00	\\xb827ebfffe78ffce	916800000	5
677	2026-05-06 11:50:28.012175+00	\\xe45f01fffe10e12e	916800000	5
678	2026-05-06 11:50:54.138882+00	\\xa840411b7dcc4150	916800000	5
679	2026-05-06 12:48:23.607259+00	\\xb827ebfffea04db6	916800000	5
680	2026-05-06 12:48:50.71833+00	\\xb827ebfffe158993	916800000	5
681	2026-05-06 12:49:16.821527+00	\\xb827ebfffef81e69	916800000	5
682	2026-05-06 12:49:46.946294+00	\\xb827ebfffe78ffce	916800000	5
683	2026-05-06 12:50:28.112311+00	\\xe45f01fffe10e12e	916800000	5
684	2026-05-06 12:50:54.221485+00	\\xa840411b7dcc4150	916800000	5
685	2026-05-06 13:48:24.526571+00	\\xb827ebfffea04db6	916800000	5
686	2026-05-06 13:48:51.625962+00	\\xb827ebfffe158993	916800000	5
687	2026-05-06 13:49:17.726688+00	\\xb827ebfffef81e69	916800000	5
688	2026-05-06 13:49:47.847799+00	\\xb827ebfffe78ffce	916800000	5
689	2026-05-06 13:50:29.017571+00	\\xe45f01fffe10e12e	916800000	5
690	2026-05-06 13:50:55.135619+00	\\xa840411b7dcc4150	916800000	5
691	2026-05-06 14:48:25.420254+00	\\xb827ebfffea04db6	916800000	5
692	2026-05-06 14:48:52.531632+00	\\xb827ebfffe158993	916800000	5
693	2026-05-06 14:49:18.620042+00	\\xb827ebfffef81e69	916800000	5
694	2026-05-06 14:49:48.744152+00	\\xb827ebfffe78ffce	916800000	5
695	2026-05-06 14:50:30.003438+00	\\xe45f01fffe10e12e	916800000	5
696	2026-05-06 14:50:56.149771+00	\\xa840411b7dcc4150	916800000	5
697	2026-05-06 15:48:25.504379+00	\\xb827ebfffea04db6	916800000	5
698	2026-05-06 15:48:52.643706+00	\\xb827ebfffe158993	916800000	5
699	2026-05-06 15:49:18.777268+00	\\xb827ebfffef81e69	916800000	5
700	2026-05-06 15:49:48.896132+00	\\xb827ebfffe78ffce	916800000	5
701	2026-05-06 15:50:30.062215+00	\\xe45f01fffe10e12e	916800000	5
702	2026-05-06 15:50:56.16958+00	\\xa840411b7dcc4150	916800000	5
703	2026-05-06 16:48:25.549193+00	\\xb827ebfffea04db6	916800000	5
704	2026-05-06 16:48:52.707585+00	\\xb827ebfffe158993	916800000	5
705	2026-05-06 16:49:18.835071+00	\\xb827ebfffef81e69	916800000	5
706	2026-05-06 16:49:48.961621+00	\\xb827ebfffe78ffce	916800000	5
707	2026-05-06 16:50:30.16999+00	\\xe45f01fffe10e12e	916800000	5
708	2026-05-06 16:50:56.322877+00	\\xa840411b7dcc4150	916800000	5
709	2026-05-06 17:48:25.704189+00	\\xb827ebfffea04db6	916800000	5
710	2026-05-06 17:48:52.80018+00	\\xb827ebfffe158993	916800000	5
711	2026-05-06 17:49:18.910698+00	\\xb827ebfffef81e69	916800000	5
712	2026-05-06 17:49:49.028349+00	\\xb827ebfffe78ffce	916800000	5
713	2026-05-06 17:50:30.202418+00	\\xe45f01fffe10e12e	916800000	5
714	2026-05-06 17:50:57.319257+00	\\xa840411b7dcc4150	916800000	5
715	2026-05-06 18:48:26.598793+00	\\xb827ebfffea04db6	916800000	5
716	2026-05-06 18:48:53.69681+00	\\xb827ebfffe158993	916800000	5
717	2026-05-06 18:49:19.800737+00	\\xb827ebfffef81e69	916800000	5
718	2026-05-06 18:49:49.916343+00	\\xb827ebfffe78ffce	916800000	5
719	2026-05-06 18:50:31.079188+00	\\xe45f01fffe10e12e	916800000	5
720	2026-05-06 18:50:58.183148+00	\\xa840411b7dcc4150	916800000	5
721	2026-05-06 19:48:27.383777+00	\\xb827ebfffea04db6	916800000	5
722	2026-05-06 19:48:54.483456+00	\\xb827ebfffe158993	916800000	5
723	2026-05-06 19:49:20.583717+00	\\xb827ebfffef81e69	916800000	5
724	2026-05-06 19:49:50.702965+00	\\xb827ebfffe78ffce	916800000	5
725	2026-05-06 19:50:31.967448+00	\\xe45f01fffe10e12e	916800000	5
726	2026-05-06 19:50:59.098007+00	\\xa840411b7dcc4150	916800000	5
727	2026-05-06 20:48:27.514341+00	\\xb827ebfffea04db6	916800000	5
728	2026-05-06 20:48:54.653943+00	\\xb827ebfffe158993	916800000	5
729	2026-05-06 20:49:20.7851+00	\\xb827ebfffef81e69	916800000	5
730	2026-05-06 20:49:50.907052+00	\\xb827ebfffe78ffce	916800000	5
731	2026-05-06 20:50:32.105661+00	\\xe45f01fffe10e12e	916800000	5
732	2026-05-06 20:50:59.191837+00	\\xa840411b7dcc4150	916800000	5
733	2026-05-06 21:48:28.475652+00	\\xb827ebfffea04db6	916800000	5
734	2026-05-06 21:48:55.608597+00	\\xb827ebfffe158993	916800000	5
735	2026-05-06 21:49:21.740682+00	\\xb827ebfffef81e69	916800000	5
736	2026-05-06 21:49:51.895772+00	\\xb827ebfffe78ffce	916800000	5
737	2026-05-06 21:50:33.087912+00	\\xe45f01fffe10e12e	916800000	5
738	2026-05-06 21:50:59.247185+00	\\xa840411b7dcc4150	916800000	5
739	2026-05-06 22:48:28.586812+00	\\xb827ebfffea04db6	916800000	5
740	2026-05-06 22:48:55.687721+00	\\xb827ebfffe158993	916800000	5
741	2026-05-06 22:49:21.789848+00	\\xb827ebfffef81e69	916800000	5
742	2026-05-06 22:49:51.904732+00	\\xb827ebfffe78ffce	916800000	5
743	2026-05-06 22:50:34.080281+00	\\xe45f01fffe10e12e	916800000	5
744	2026-05-06 22:51:00.182787+00	\\xa840411b7dcc4150	916800000	5
745	2026-05-06 23:48:29.550015+00	\\xb827ebfffea04db6	916800000	5
746	2026-05-06 23:48:56.644496+00	\\xb827ebfffe158993	916800000	5
747	2026-05-06 23:49:22.735735+00	\\xb827ebfffef81e69	916800000	5
748	2026-05-06 23:49:52.871683+00	\\xb827ebfffe78ffce	916800000	5
749	2026-05-06 23:50:35.039104+00	\\xe45f01fffe10e12e	916800000	5
750	2026-05-06 23:51:01.136719+00	\\xa840411b7dcc4150	916800000	5
751	2026-05-07 00:48:30.441298+00	\\xb827ebfffea04db6	916800000	5
752	2026-05-07 00:48:57.54811+00	\\xb827ebfffe158993	916800000	5
753	2026-05-07 00:49:23.650823+00	\\xb827ebfffef81e69	916800000	5
754	2026-05-07 00:49:53.869622+00	\\xb827ebfffe78ffce	916800000	5
755	2026-05-07 00:50:35.076284+00	\\xe45f01fffe10e12e	916800000	5
756	2026-05-07 00:51:01.219028+00	\\xa840411b7dcc4150	916800000	5
757	2026-05-07 01:48:31.436334+00	\\xb827ebfffea04db6	916800000	5
758	2026-05-07 01:48:57.561465+00	\\xb827ebfffe158993	916800000	5
759	2026-05-07 01:49:23.697669+00	\\xb827ebfffef81e69	916800000	5
760	2026-05-07 01:49:54.845741+00	\\xb827ebfffe78ffce	916800000	5
761	2026-05-07 01:50:36.011056+00	\\xe45f01fffe10e12e	916800000	5
762	2026-05-07 01:51:02.114731+00	\\xa840411b7dcc4150	916800000	5
763	2026-05-07 02:48:32.44427+00	\\xb827ebfffea04db6	916800000	5
764	2026-05-07 02:48:57.575132+00	\\xb827ebfffe158993	916800000	5
765	2026-05-07 02:49:23.713906+00	\\xb827ebfffef81e69	916800000	5
766	2026-05-07 02:49:54.880934+00	\\xb827ebfffe78ffce	916800000	5
767	2026-05-07 02:50:36.04888+00	\\xe45f01fffe10e12e	916800000	5
768	2026-05-07 02:51:02.177676+00	\\xa840411b7dcc4150	916800000	5
769	2026-05-07 03:48:32.664341+00	\\xb827ebfffea04db6	916800000	5
770	2026-05-07 03:48:57.756034+00	\\xb827ebfffe158993	916800000	5
771	2026-05-07 03:49:23.8531+00	\\xb827ebfffef81e69	916800000	5
772	2026-05-07 03:49:54.962956+00	\\xb827ebfffe78ffce	916800000	5
773	2026-05-07 03:50:36.133809+00	\\xe45f01fffe10e12e	916800000	5
774	2026-05-07 03:51:02.234695+00	\\xa840411b7dcc4150	916800000	5
775	2026-05-07 04:48:32.956737+00	\\xb827ebfffea04db6	916800000	5
776	2026-05-07 04:48:58.045698+00	\\xb827ebfffe158993	916800000	5
777	2026-05-07 04:49:24.127922+00	\\xb827ebfffef81e69	916800000	5
778	2026-05-07 04:49:55.222545+00	\\xb827ebfffe78ffce	916800000	5
779	2026-05-07 04:50:36.350758+00	\\xe45f01fffe10e12e	916800000	5
780	2026-05-07 04:51:02.438734+00	\\xa840411b7dcc4150	916800000	5
781	2026-05-07 05:48:33.328006+00	\\xb827ebfffea04db6	916800000	5
782	2026-05-07 05:48:58.422013+00	\\xb827ebfffe158993	916800000	5
783	2026-05-07 05:49:24.522232+00	\\xb827ebfffef81e69	916800000	5
784	2026-05-07 05:49:55.644386+00	\\xb827ebfffe78ffce	916800000	5
785	2026-05-07 05:50:36.895821+00	\\xe45f01fffe10e12e	916800000	5
786	2026-05-07 05:51:03.024815+00	\\xa840411b7dcc4150	916800000	5
787	2026-05-07 06:48:34.082062+00	\\xb827ebfffea04db6	916800000	5
788	2026-05-07 06:48:59.211011+00	\\xb827ebfffe158993	916800000	5
789	2026-05-07 06:49:25.319469+00	\\xb827ebfffef81e69	916800000	5
790	2026-05-07 06:49:56.453258+00	\\xb827ebfffe78ffce	916800000	5
791	2026-05-07 06:50:37.671668+00	\\xe45f01fffe10e12e	916800000	5
792	2026-05-07 06:51:03.831402+00	\\xa840411b7dcc4150	916800000	5
793	2026-05-07 07:48:35.051089+00	\\xb827ebfffea04db6	916800000	5
794	2026-05-07 07:49:00.147216+00	\\xb827ebfffe158993	916800000	5
795	2026-05-07 07:49:26.2387+00	\\xb827ebfffef81e69	916800000	5
796	2026-05-07 07:49:57.395112+00	\\xb827ebfffe78ffce	916800000	5
797	2026-05-07 07:50:38.671003+00	\\xe45f01fffe10e12e	916800000	5
798	2026-05-07 07:51:04.822335+00	\\xa840411b7dcc4150	916800000	5
799	2026-05-07 08:48:35.274416+00	\\xb827ebfffea04db6	916800000	5
800	2026-05-07 08:49:00.365889+00	\\xb827ebfffe158993	916800000	5
801	2026-05-07 08:49:26.470907+00	\\xb827ebfffef81e69	916800000	5
802	2026-05-07 08:49:57.590114+00	\\xb827ebfffe78ffce	916800000	5
803	2026-05-07 08:50:38.756995+00	\\xe45f01fffe10e12e	916800000	5
804	2026-05-07 08:51:04.872277+00	\\xa840411b7dcc4150	916800000	5
805	2026-05-07 09:48:36.190446+00	\\xb827ebfffea04db6	916800000	5
806	2026-05-07 09:49:01.282223+00	\\xb827ebfffe158993	916800000	5
807	2026-05-07 09:49:27.380464+00	\\xb827ebfffef81e69	916800000	5
808	2026-05-07 09:49:58.49413+00	\\xb827ebfffe78ffce	916800000	5
809	2026-05-07 09:50:39.653147+00	\\xe45f01fffe10e12e	916800000	5
810	2026-05-07 09:51:05.753829+00	\\xa840411b7dcc4150	916800000	5
811	2026-05-07 10:48:37.104643+00	\\xb827ebfffea04db6	916800000	5
812	2026-05-07 10:49:02.193634+00	\\xb827ebfffe158993	916800000	5
813	2026-05-07 10:49:28.299476+00	\\xb827ebfffef81e69	916800000	5
814	2026-05-07 10:49:59.421149+00	\\xb827ebfffe78ffce	916800000	5
815	2026-05-07 10:50:40.581095+00	\\xe45f01fffe10e12e	916800000	5
816	2026-05-07 10:51:06.69304+00	\\xa840411b7dcc4150	916800000	5
817	2026-05-07 11:48:38.052133+00	\\xb827ebfffea04db6	916800000	5
818	2026-05-07 11:49:03.193599+00	\\xb827ebfffe158993	916800000	5
819	2026-05-07 11:49:29.301615+00	\\xb827ebfffef81e69	916800000	5
820	2026-05-07 11:49:59.441805+00	\\xb827ebfffe78ffce	916800000	5
821	2026-05-07 11:50:40.679868+00	\\xe45f01fffe10e12e	916800000	5
822	2026-05-07 11:51:06.812399+00	\\xa840411b7dcc4150	916800000	5
823	2026-05-07 12:48:38.195119+00	\\xb827ebfffea04db6	916800000	5
824	2026-05-07 12:49:03.291674+00	\\xb827ebfffe158993	916800000	5
825	2026-05-07 12:49:29.399341+00	\\xb827ebfffef81e69	916800000	5
826	2026-05-07 12:49:59.617983+00	\\xb827ebfffe78ffce	916800000	5
827	2026-05-07 12:50:40.851311+00	\\xe45f01fffe10e12e	916800000	5
828	2026-05-07 12:51:06.964685+00	\\xa840411b7dcc4150	916800000	5
829	2026-05-07 13:48:38.503623+00	\\xb827ebfffea04db6	916800000	5
830	2026-05-07 13:49:03.615339+00	\\xb827ebfffe158993	916800000	5
831	2026-05-07 13:49:29.717197+00	\\xb827ebfffef81e69	916800000	5
832	2026-05-07 13:49:59.83106+00	\\xb827ebfffe78ffce	916800000	5
833	2026-05-07 13:50:41.02822+00	\\xe45f01fffe10e12e	916800000	5
834	2026-05-07 13:51:07.155267+00	\\xa840411b7dcc4150	916800000	5
835	2026-05-07 14:48:39.362716+00	\\xb827ebfffea04db6	916800000	5
836	2026-05-07 14:49:04.462194+00	\\xb827ebfffe158993	916800000	5
837	2026-05-07 14:49:30.545323+00	\\xb827ebfffef81e69	916800000	5
838	2026-05-07 14:50:00.637039+00	\\xb827ebfffe78ffce	916800000	5
839	2026-05-07 14:50:41.811411+00	\\xe45f01fffe10e12e	916800000	5
840	2026-05-07 14:51:07.9077+00	\\xa840411b7dcc4150	916800000	5
841	2026-05-07 15:48:40.071303+00	\\xb827ebfffea04db6	916800000	5
842	2026-05-07 15:49:05.167166+00	\\xb827ebfffe158993	916800000	5
843	2026-05-07 15:49:31.274801+00	\\xb827ebfffef81e69	916800000	5
844	2026-05-07 15:50:01.394208+00	\\xb827ebfffe78ffce	916800000	5
845	2026-05-07 15:50:42.546579+00	\\xe45f01fffe10e12e	916800000	5
846	2026-05-07 15:51:08.643869+00	\\xa840411b7dcc4150	916800000	5
847	2026-05-07 16:48:40.160745+00	\\xb827ebfffea04db6	916800000	5
848	2026-05-07 16:49:05.267041+00	\\xb827ebfffe158993	916800000	5
849	2026-05-07 16:49:31.396646+00	\\xb827ebfffef81e69	916800000	5
850	2026-05-07 16:50:01.586482+00	\\xb827ebfffe78ffce	916800000	5
851	2026-05-07 16:50:42.761436+00	\\xe45f01fffe10e12e	916800000	5
852	2026-05-07 16:51:08.876553+00	\\xa840411b7dcc4150	916800000	5
853	2026-05-07 17:48:41.167519+00	\\xb827ebfffea04db6	916800000	5
854	2026-05-07 17:49:06.266293+00	\\xb827ebfffe158993	916800000	5
855	2026-05-07 17:49:31.412502+00	\\xb827ebfffef81e69	916800000	5
856	2026-05-07 17:50:01.625527+00	\\xb827ebfffe78ffce	916800000	5
857	2026-05-07 17:50:42.869125+00	\\xe45f01fffe10e12e	916800000	5
858	2026-05-07 17:51:08.969078+00	\\xa840411b7dcc4150	916800000	5
859	2026-05-07 18:48:41.343562+00	\\xb827ebfffea04db6	916800000	5
860	2026-05-07 18:49:06.450065+00	\\xb827ebfffe158993	916800000	5
861	2026-05-07 18:49:31.547759+00	\\xb827ebfffef81e69	916800000	5
862	2026-05-07 18:50:01.669148+00	\\xb827ebfffe78ffce	916800000	5
863	2026-05-07 18:50:43.840211+00	\\xe45f01fffe10e12e	916800000	5
864	2026-05-07 18:51:09.945822+00	\\xa840411b7dcc4150	916800000	5
865	2026-05-07 19:48:42.312051+00	\\xb827ebfffea04db6	916800000	5
866	2026-05-07 19:49:07.412516+00	\\xb827ebfffe158993	916800000	5
867	2026-05-07 19:49:32.514684+00	\\xb827ebfffef81e69	916800000	5
868	2026-05-07 19:50:02.630028+00	\\xb827ebfffe78ffce	916800000	5
869	2026-05-07 19:50:44.801432+00	\\xe45f01fffe10e12e	916800000	5
870	2026-05-07 19:51:10.905768+00	\\xa840411b7dcc4150	916800000	5
871	2026-05-07 20:48:42.389583+00	\\xb827ebfffea04db6	916800000	5
872	2026-05-07 20:49:07.48978+00	\\xb827ebfffe158993	916800000	5
873	2026-05-07 20:49:32.583365+00	\\xb827ebfffef81e69	916800000	5
874	2026-05-07 20:50:02.697152+00	\\xb827ebfffe78ffce	916800000	5
875	2026-05-07 20:50:44.936551+00	\\xe45f01fffe10e12e	916800000	5
876	2026-05-07 20:51:11.073338+00	\\xa840411b7dcc4150	916800000	5
877	2026-05-07 21:48:43.322705+00	\\xb827ebfffea04db6	916800000	5
878	2026-05-07 21:49:08.441128+00	\\xb827ebfffe158993	916800000	5
879	2026-05-07 21:49:33.520937+00	\\xb827ebfffef81e69	916800000	5
880	2026-05-07 21:50:03.645999+00	\\xb827ebfffe78ffce	916800000	5
881	2026-05-07 21:50:45.843113+00	\\xe45f01fffe10e12e	916800000	5
882	2026-05-07 21:51:11.950176+00	\\xa840411b7dcc4150	916800000	5
883	2026-05-07 22:48:43.428521+00	\\xb827ebfffea04db6	916800000	5
884	2026-05-07 22:49:08.561126+00	\\xb827ebfffe158993	916800000	5
885	2026-05-07 22:49:33.7096+00	\\xb827ebfffef81e69	916800000	5
886	2026-05-07 22:50:03.866608+00	\\xb827ebfffe78ffce	916800000	5
887	2026-05-07 22:50:46.041655+00	\\xe45f01fffe10e12e	916800000	5
888	2026-05-07 22:51:12.160242+00	\\xa840411b7dcc4150	916800000	5
889	2026-05-07 23:48:43.669904+00	\\xb827ebfffea04db6	916800000	5
890	2026-05-07 23:49:08.763668+00	\\xb827ebfffe158993	916800000	5
891	2026-05-07 23:49:33.863385+00	\\xb827ebfffef81e69	916800000	5
892	2026-05-07 23:50:03.984306+00	\\xb827ebfffe78ffce	916800000	5
893	2026-05-07 23:50:46.156226+00	\\xe45f01fffe10e12e	916800000	5
894	2026-05-07 23:51:12.257612+00	\\xa840411b7dcc4150	916800000	5
895	2026-05-08 00:48:44.492856+00	\\xb827ebfffea04db6	916800000	5
896	2026-05-08 00:49:09.586884+00	\\xb827ebfffe158993	916800000	5
897	2026-05-08 00:49:34.697213+00	\\xb827ebfffef81e69	916800000	5
898	2026-05-08 00:50:04.817859+00	\\xb827ebfffe78ffce	916800000	5
899	2026-05-08 00:50:46.991307+00	\\xe45f01fffe10e12e	916800000	5
900	2026-05-08 00:51:13.094099+00	\\xa840411b7dcc4150	916800000	5
901	2026-05-08 01:48:45.188678+00	\\xb827ebfffea04db6	916800000	5
902	2026-05-08 01:49:10.284747+00	\\xb827ebfffe158993	916800000	5
903	2026-05-08 01:49:35.38968+00	\\xb827ebfffef81e69	916800000	5
904	2026-05-08 01:50:05.499886+00	\\xb827ebfffe78ffce	916800000	5
905	2026-05-08 01:50:47.661299+00	\\xe45f01fffe10e12e	916800000	5
906	2026-05-08 01:51:13.811741+00	\\xa840411b7dcc4150	916800000	5
907	2026-05-08 02:48:46.147258+00	\\xb827ebfffea04db6	916800000	5
908	2026-05-08 02:49:11.251635+00	\\xb827ebfffe158993	916800000	5
909	2026-05-08 02:49:36.361489+00	\\xb827ebfffef81e69	916800000	5
910	2026-05-08 02:50:05.50443+00	\\xb827ebfffe78ffce	916800000	5
911	2026-05-08 02:50:47.714245+00	\\xe45f01fffe10e12e	916800000	5
912	2026-05-08 02:51:13.845298+00	\\xa840411b7dcc4150	916800000	5
913	2026-05-08 03:48:46.190778+00	\\xb827ebfffea04db6	916800000	5
914	2026-05-08 03:49:11.280693+00	\\xb827ebfffe158993	916800000	5
915	2026-05-08 03:49:36.379549+00	\\xb827ebfffef81e69	916800000	5
916	2026-05-08 03:50:05.548239+00	\\xb827ebfffe78ffce	916800000	5
917	2026-05-08 03:50:47.797344+00	\\xe45f01fffe10e12e	916800000	5
918	2026-05-08 03:51:13.92169+00	\\xa840411b7dcc4150	916800000	5
919	2026-05-08 04:48:46.304421+00	\\xb827ebfffea04db6	916800000	5
920	2026-05-08 04:49:11.41084+00	\\xb827ebfffe158993	916800000	5
921	2026-05-08 04:49:36.497103+00	\\xb827ebfffef81e69	916800000	5
922	2026-05-08 04:50:05.600073+00	\\xb827ebfffe78ffce	916800000	5
923	2026-05-08 04:50:48.773002+00	\\xe45f01fffe10e12e	916800000	5
924	2026-05-08 04:51:14.898949+00	\\xa840411b7dcc4150	916800000	5
925	2026-05-08 05:48:47.141711+00	\\xb827ebfffea04db6	916800000	5
926	2026-05-08 05:49:12.239103+00	\\xb827ebfffe158993	916800000	5
927	2026-05-08 05:49:37.336035+00	\\xb827ebfffef81e69	916800000	5
928	2026-05-08 05:50:06.452954+00	\\xb827ebfffe78ffce	916800000	5
929	2026-05-08 05:50:49.633126+00	\\xe45f01fffe10e12e	916800000	5
930	2026-05-08 05:51:15.73794+00	\\xa840411b7dcc4150	916800000	5
931	2026-05-08 06:48:47.573794+00	\\xb827ebfffea04db6	916800000	5
932	2026-05-08 06:49:12.766286+00	\\xb827ebfffe158993	916800000	5
933	2026-05-08 06:49:37.880214+00	\\xb827ebfffef81e69	916800000	5
934	2026-05-08 06:50:07.00897+00	\\xb827ebfffe78ffce	916800000	5
935	2026-05-08 06:50:50.192595+00	\\xe45f01fffe10e12e	916800000	5
936	2026-05-08 06:51:16.312183+00	\\xa840411b7dcc4150	916800000	5
937	2026-05-08 07:48:47.792571+00	\\xb827ebfffea04db6	916800000	5
938	2026-05-08 07:49:12.894405+00	\\xb827ebfffe158993	916800000	5
939	2026-05-08 07:49:37.998966+00	\\xb827ebfffef81e69	916800000	5
940	2026-05-08 07:50:07.12282+00	\\xb827ebfffe78ffce	916800000	5
941	2026-05-08 07:50:50.311457+00	\\xe45f01fffe10e12e	916800000	5
942	2026-05-08 07:51:16.424968+00	\\xa840411b7dcc4150	916800000	5
943	2026-05-08 08:48:47.917695+00	\\xb827ebfffea04db6	916800000	5
944	2026-05-08 08:49:13.019976+00	\\xb827ebfffe158993	916800000	5
945	2026-05-08 08:49:38.119634+00	\\xb827ebfffef81e69	916800000	5
946	2026-05-08 08:50:07.240013+00	\\xb827ebfffe78ffce	916800000	5
947	2026-05-08 08:50:50.41637+00	\\xe45f01fffe10e12e	916800000	5
948	2026-05-08 08:51:16.533401+00	\\xa840411b7dcc4150	916800000	5
949	2026-05-08 09:48:48.085054+00	\\xb827ebfffea04db6	916800000	5
950	2026-05-08 09:49:13.212966+00	\\xb827ebfffe158993	916800000	5
951	2026-05-08 09:49:38.307+00	\\xb827ebfffef81e69	916800000	5
952	2026-05-08 09:50:07.428115+00	\\xb827ebfffe78ffce	916800000	5
953	2026-05-08 09:50:50.634877+00	\\xe45f01fffe10e12e	916800000	5
954	2026-05-08 09:51:16.773678+00	\\xa840411b7dcc4150	916800000	5
955	2026-05-08 10:48:48.894774+00	\\xb827ebfffea04db6	916800000	5
956	2026-05-08 10:49:13.991424+00	\\xb827ebfffe158993	916800000	5
957	2026-05-08 10:49:39.084753+00	\\xb827ebfffef81e69	916800000	5
958	2026-05-08 10:50:08.195302+00	\\xb827ebfffe78ffce	916800000	5
959	2026-05-08 10:50:51.356238+00	\\xe45f01fffe10e12e	916800000	5
960	2026-05-08 10:51:17.502972+00	\\xa840411b7dcc4150	916800000	5
961	2026-05-08 11:48:49.119677+00	\\xb827ebfffea04db6	916800000	5
962	2026-05-08 11:49:14.287954+00	\\xb827ebfffe158993	916800000	5
963	2026-05-08 11:49:39.384819+00	\\xb827ebfffef81e69	916800000	5
964	2026-05-08 11:50:08.499463+00	\\xb827ebfffe78ffce	916800000	5
965	2026-05-08 11:50:51.670393+00	\\xe45f01fffe10e12e	916800000	5
966	2026-05-08 11:51:17.760462+00	\\xa840411b7dcc4150	916800000	5
967	2026-05-08 12:48:49.552507+00	\\xb827ebfffea04db6	916800000	5
968	2026-05-08 12:49:14.64634+00	\\xb827ebfffe158993	916800000	5
969	2026-05-08 12:49:39.746109+00	\\xb827ebfffef81e69	916800000	5
970	2026-05-08 12:50:08.852922+00	\\xb827ebfffe78ffce	916800000	5
971	2026-05-08 12:50:52.048498+00	\\xe45f01fffe10e12e	916800000	5
972	2026-05-08 12:51:18.144848+00	\\xa840411b7dcc4150	916800000	5
973	2026-05-08 13:48:50.553726+00	\\xb827ebfffea04db6	916800000	5
974	2026-05-08 13:49:15.64922+00	\\xb827ebfffe158993	916800000	5
975	2026-05-08 13:49:40.798344+00	\\xb827ebfffef81e69	916800000	5
976	2026-05-08 13:50:08.942751+00	\\xb827ebfffe78ffce	916800000	5
977	2026-05-08 13:50:52.133408+00	\\xe45f01fffe10e12e	916800000	5
978	2026-05-08 13:51:18.27111+00	\\xa840411b7dcc4150	916800000	5
979	2026-05-08 14:48:50.570797+00	\\xb827ebfffea04db6	916800000	5
980	2026-05-08 14:49:15.69587+00	\\xb827ebfffe158993	916800000	5
981	2026-05-08 14:49:40.821606+00	\\xb827ebfffef81e69	916800000	5
982	2026-05-08 14:50:08.948753+00	\\xb827ebfffe78ffce	916800000	5
983	2026-05-08 14:50:53.131851+00	\\xe45f01fffe10e12e	916800000	5
984	2026-05-08 14:51:19.264093+00	\\xa840411b7dcc4150	916800000	5
985	2026-05-08 15:48:50.93574+00	\\xb827ebfffea04db6	916800000	5
986	2026-05-08 15:49:16.044826+00	\\xb827ebfffe158993	916800000	5
987	2026-05-08 15:49:41.175596+00	\\xb827ebfffef81e69	916800000	5
988	2026-05-08 15:50:09.331721+00	\\xb827ebfffe78ffce	916800000	5
989	2026-05-08 15:50:53.519188+00	\\xe45f01fffe10e12e	916800000	5
990	2026-05-08 15:51:19.6241+00	\\xa840411b7dcc4150	916800000	5
991	2026-05-08 16:48:51.118292+00	\\xb827ebfffea04db6	916800000	5
165529	2026-05-10 15:48:08.943192+00	\\xb827ebfffe158993	916800000	5
165530	2026-05-10 15:48:09.976041+00	\\xb827ebfffef81e69	916800000	5
165531	2026-05-10 15:48:10.986158+00	\\xb827ebfffe78ffce	916800000	5
165532	2026-05-10 15:48:11.996574+00	\\xe45f01fffe10e12e	916800000	5
165533	2026-05-10 15:48:13.006358+00	\\xa840411b7dcc4150	916800000	5
165534	2026-05-10 15:48:14.017699+00	\\xb827ebfffea04db6	916800000	5
165691	2026-05-11 18:48:21.954683+00	\\xb827ebfffe158993	916800000	5
165692	2026-05-11 18:48:22.977141+00	\\xb827ebfffef81e69	916800000	5
165693	2026-05-11 18:48:23.991706+00	\\xb827ebfffe78ffce	916800000	5
165694	2026-05-11 18:48:25.001211+00	\\xe45f01fffe10e12e	916800000	5
165695	2026-05-11 18:48:26.013053+00	\\xa840411b7dcc4150	916800000	5
165696	2026-05-11 18:48:27.025736+00	\\xb827ebfffea04db6	916800000	5
165697	2026-05-11 19:48:22.44388+00	\\xb827ebfffe158993	916800000	5
165698	2026-05-11 19:48:23.470814+00	\\xb827ebfffef81e69	916800000	5
165699	2026-05-11 19:48:24.481299+00	\\xb827ebfffe78ffce	916800000	5
165700	2026-05-11 19:48:25.492671+00	\\xe45f01fffe10e12e	916800000	5
165701	2026-05-11 19:48:26.505584+00	\\xa840411b7dcc4150	916800000	5
165702	2026-05-11 19:48:27.515198+00	\\xb827ebfffea04db6	916800000	5
165703	2026-05-11 20:48:22.488983+00	\\xb827ebfffe158993	916800000	5
165704	2026-05-11 20:48:23.51208+00	\\xb827ebfffef81e69	916800000	5
165705	2026-05-11 20:48:24.521984+00	\\xb827ebfffe78ffce	916800000	5
165706	2026-05-11 20:48:25.531943+00	\\xe45f01fffe10e12e	916800000	5
165707	2026-05-11 20:48:26.543465+00	\\xa840411b7dcc4150	916800000	5
165708	2026-05-11 20:48:27.554828+00	\\xb827ebfffea04db6	916800000	5
165709	2026-05-11 21:48:23.458414+00	\\xb827ebfffe158993	916800000	5
165710	2026-05-11 21:48:24.47866+00	\\xb827ebfffef81e69	916800000	5
165711	2026-05-11 21:48:25.48802+00	\\xb827ebfffe78ffce	916800000	5
165712	2026-05-11 21:48:26.497119+00	\\xe45f01fffe10e12e	916800000	5
165713	2026-05-11 21:48:27.506233+00	\\xa840411b7dcc4150	916800000	5
165714	2026-05-11 21:48:28.516394+00	\\xb827ebfffea04db6	916800000	5
165715	2026-05-11 22:48:24.131494+00	\\xb827ebfffe158993	916800000	5
165716	2026-05-11 22:48:25.148697+00	\\xb827ebfffef81e69	916800000	5
165717	2026-05-11 22:48:26.1583+00	\\xb827ebfffe78ffce	916800000	5
165718	2026-05-11 22:48:27.167949+00	\\xe45f01fffe10e12e	916800000	5
165719	2026-05-11 22:48:28.177504+00	\\xa840411b7dcc4150	916800000	5
165720	2026-05-11 22:48:29.190002+00	\\xb827ebfffea04db6	916800000	5
165721	2026-05-11 23:48:24.724006+00	\\xb827ebfffe158993	916800000	5
165722	2026-05-11 23:48:25.740564+00	\\xb827ebfffef81e69	916800000	5
165723	2026-05-11 23:48:26.74993+00	\\xb827ebfffe78ffce	916800000	5
165724	2026-05-11 23:48:27.759591+00	\\xe45f01fffe10e12e	916800000	5
165725	2026-05-11 23:48:28.76863+00	\\xa840411b7dcc4150	916800000	5
165726	2026-05-11 23:48:29.777911+00	\\xb827ebfffea04db6	916800000	5
165727	2026-05-12 00:48:24.952476+00	\\xb827ebfffe158993	916800000	5
165728	2026-05-12 00:48:25.971933+00	\\xb827ebfffef81e69	916800000	5
165729	2026-05-12 00:48:26.982543+00	\\xb827ebfffe78ffce	916800000	5
165730	2026-05-12 00:48:27.991978+00	\\xe45f01fffe10e12e	916800000	5
165731	2026-05-12 00:48:29.001841+00	\\xa840411b7dcc4150	916800000	5
165732	2026-05-12 00:48:30.012501+00	\\xb827ebfffea04db6	916800000	5
165733	2026-05-12 01:48:25.355577+00	\\xb827ebfffe158993	916800000	5
165734	2026-05-12 01:48:26.372704+00	\\xb827ebfffef81e69	916800000	5
165735	2026-05-12 01:48:27.382272+00	\\xb827ebfffe78ffce	916800000	5
165736	2026-05-12 01:48:28.393266+00	\\xe45f01fffe10e12e	916800000	5
165737	2026-05-12 01:48:29.40313+00	\\xa840411b7dcc4150	916800000	5
165738	2026-05-12 01:48:30.414901+00	\\xb827ebfffea04db6	916800000	5
165739	2026-05-12 02:48:25.710865+00	\\xb827ebfffe158993	916800000	5
165740	2026-05-12 02:48:26.728214+00	\\xb827ebfffef81e69	916800000	5
165741	2026-05-12 02:48:27.74519+00	\\xb827ebfffe78ffce	916800000	5
165742	2026-05-12 02:48:28.756031+00	\\xe45f01fffe10e12e	916800000	5
165743	2026-05-12 02:48:29.76584+00	\\xa840411b7dcc4150	916800000	5
165744	2026-05-12 02:48:30.776449+00	\\xb827ebfffea04db6	916800000	5
165745	2026-05-12 03:48:26.587393+00	\\xb827ebfffe158993	916800000	5
165746	2026-05-12 03:48:27.604881+00	\\xb827ebfffef81e69	916800000	5
165747	2026-05-12 03:48:28.614136+00	\\xb827ebfffe78ffce	916800000	5
165748	2026-05-12 03:48:29.623879+00	\\xe45f01fffe10e12e	916800000	5
165749	2026-05-12 03:48:30.634208+00	\\xa840411b7dcc4150	916800000	5
165750	2026-05-12 03:48:31.645713+00	\\xb827ebfffea04db6	916800000	5
165751	2026-05-12 04:48:26.943063+00	\\xb827ebfffe158993	916800000	5
165752	2026-05-12 04:48:27.962828+00	\\xb827ebfffef81e69	916800000	5
165753	2026-05-12 04:48:28.974674+00	\\xb827ebfffe78ffce	916800000	5
165754	2026-05-12 04:48:29.984856+00	\\xe45f01fffe10e12e	916800000	5
165755	2026-05-12 04:48:30.994103+00	\\xa840411b7dcc4150	916800000	5
165756	2026-05-12 04:48:32.005712+00	\\xb827ebfffea04db6	916800000	5
165757	2026-05-12 05:48:27.509811+00	\\xb827ebfffe158993	916800000	5
165758	2026-05-12 05:48:28.526907+00	\\xb827ebfffef81e69	916800000	5
165759	2026-05-12 05:48:29.536297+00	\\xb827ebfffe78ffce	916800000	5
165760	2026-05-12 05:48:30.546478+00	\\xe45f01fffe10e12e	916800000	5
165761	2026-05-12 05:48:31.558916+00	\\xa840411b7dcc4150	916800000	5
165762	2026-05-12 05:48:32.574139+00	\\xb827ebfffea04db6	916800000	5
165763	2026-05-12 06:48:27.943767+00	\\xb827ebfffe158993	916800000	5
165764	2026-05-12 06:48:28.96276+00	\\xb827ebfffef81e69	916800000	5
165765	2026-05-12 06:48:29.972013+00	\\xb827ebfffe78ffce	916800000	5
165766	2026-05-12 06:48:30.981876+00	\\xe45f01fffe10e12e	916800000	5
165767	2026-05-12 06:48:31.994319+00	\\xa840411b7dcc4150	916800000	5
165768	2026-05-12 06:48:33.003806+00	\\xb827ebfffea04db6	916800000	5
165769	2026-05-12 07:48:28.840099+00	\\xb827ebfffe158993	916800000	5
165770	2026-05-12 07:48:29.859047+00	\\xb827ebfffef81e69	916800000	5
165771	2026-05-12 07:48:30.873247+00	\\xb827ebfffe78ffce	916800000	5
165772	2026-05-12 07:48:31.890558+00	\\xe45f01fffe10e12e	916800000	5
165773	2026-05-12 07:48:32.900445+00	\\xa840411b7dcc4150	916800000	5
165535	2026-05-10 16:48:09.51463+00	\\xb827ebfffe158993	916800000	5
165536	2026-05-10 16:48:10.542608+00	\\xb827ebfffef81e69	916800000	5
165537	2026-05-10 16:48:11.553474+00	\\xb827ebfffe78ffce	916800000	5
165538	2026-05-10 16:48:12.567942+00	\\xe45f01fffe10e12e	916800000	5
165539	2026-05-10 16:48:13.578835+00	\\xa840411b7dcc4150	916800000	5
165540	2026-05-10 16:48:14.58937+00	\\xb827ebfffea04db6	916800000	5
165541	2026-05-10 17:48:09.815544+00	\\xb827ebfffe158993	916800000	5
165542	2026-05-10 17:48:10.851241+00	\\xb827ebfffef81e69	916800000	5
165543	2026-05-10 17:48:11.86978+00	\\xb827ebfffe78ffce	916800000	5
165544	2026-05-10 17:48:12.880456+00	\\xe45f01fffe10e12e	916800000	5
165545	2026-05-10 17:48:13.890601+00	\\xa840411b7dcc4150	916800000	5
165546	2026-05-10 17:48:14.900396+00	\\xb827ebfffea04db6	916800000	5
165547	2026-05-10 18:48:10.553482+00	\\xb827ebfffe158993	916800000	5
165548	2026-05-10 18:48:11.577206+00	\\xb827ebfffef81e69	916800000	5
165549	2026-05-10 18:48:12.589494+00	\\xb827ebfffe78ffce	916800000	5
165550	2026-05-10 18:48:13.601102+00	\\xe45f01fffe10e12e	916800000	5
165551	2026-05-10 18:48:14.610786+00	\\xa840411b7dcc4150	916800000	5
165552	2026-05-10 18:48:15.620778+00	\\xb827ebfffea04db6	916800000	5
165553	2026-05-10 19:48:11.159268+00	\\xb827ebfffe158993	916800000	5
165554	2026-05-10 19:48:12.184865+00	\\xb827ebfffef81e69	916800000	5
165555	2026-05-10 19:48:13.19846+00	\\xb827ebfffe78ffce	916800000	5
165556	2026-05-10 19:48:14.212073+00	\\xe45f01fffe10e12e	916800000	5
165557	2026-05-10 19:48:15.222189+00	\\xa840411b7dcc4150	916800000	5
165558	2026-05-10 19:48:16.232373+00	\\xb827ebfffea04db6	916800000	5
165559	2026-05-10 20:48:11.364628+00	\\xb827ebfffe158993	916800000	5
165560	2026-05-10 20:48:12.387626+00	\\xb827ebfffef81e69	916800000	5
165561	2026-05-10 20:48:13.398924+00	\\xb827ebfffe78ffce	916800000	5
165562	2026-05-10 20:48:14.40893+00	\\xe45f01fffe10e12e	916800000	5
165563	2026-05-10 20:48:15.419569+00	\\xa840411b7dcc4150	916800000	5
165564	2026-05-10 20:48:16.429475+00	\\xb827ebfffea04db6	916800000	5
165565	2026-05-10 21:48:11.39163+00	\\xb827ebfffe158993	916800000	5
165566	2026-05-10 21:48:12.435606+00	\\xb827ebfffef81e69	916800000	5
165567	2026-05-10 21:48:13.455209+00	\\xb827ebfffe78ffce	916800000	5
165568	2026-05-10 21:48:14.465772+00	\\xe45f01fffe10e12e	916800000	5
165569	2026-05-10 21:48:15.475253+00	\\xa840411b7dcc4150	916800000	5
165570	2026-05-10 21:48:16.494059+00	\\xb827ebfffea04db6	916800000	5
165571	2026-05-10 22:48:11.488379+00	\\xb827ebfffe158993	916800000	5
165572	2026-05-10 22:48:12.512137+00	\\xb827ebfffef81e69	916800000	5
165573	2026-05-10 22:48:13.526072+00	\\xb827ebfffe78ffce	916800000	5
165574	2026-05-10 22:48:14.552474+00	\\xe45f01fffe10e12e	916800000	5
165575	2026-05-10 22:48:15.56265+00	\\xa840411b7dcc4150	916800000	5
165576	2026-05-10 22:48:16.573738+00	\\xb827ebfffea04db6	916800000	5
165577	2026-05-10 23:48:11.650665+00	\\xb827ebfffe158993	916800000	5
165578	2026-05-10 23:48:12.677901+00	\\xb827ebfffef81e69	916800000	5
165579	2026-05-10 23:48:13.690876+00	\\xb827ebfffe78ffce	916800000	5
165580	2026-05-10 23:48:14.703786+00	\\xe45f01fffe10e12e	916800000	5
165581	2026-05-10 23:48:15.712944+00	\\xa840411b7dcc4150	916800000	5
165582	2026-05-10 23:48:16.722625+00	\\xb827ebfffea04db6	916800000	5
165583	2026-05-11 00:48:11.956483+00	\\xb827ebfffe158993	916800000	5
165584	2026-05-11 00:48:12.976329+00	\\xb827ebfffef81e69	916800000	5
165585	2026-05-11 00:48:13.991207+00	\\xb827ebfffe78ffce	916800000	5
165586	2026-05-11 00:48:15.002846+00	\\xe45f01fffe10e12e	916800000	5
165587	2026-05-11 00:48:16.016454+00	\\xa840411b7dcc4150	916800000	5
165588	2026-05-11 00:48:17.026192+00	\\xb827ebfffea04db6	916800000	5
165589	2026-05-11 01:48:12.836835+00	\\xb827ebfffe158993	916800000	5
165590	2026-05-11 01:48:13.86685+00	\\xb827ebfffef81e69	916800000	5
165591	2026-05-11 01:48:14.885917+00	\\xb827ebfffe78ffce	916800000	5
165592	2026-05-11 01:48:15.898257+00	\\xe45f01fffe10e12e	916800000	5
165593	2026-05-11 01:48:16.912593+00	\\xa840411b7dcc4150	916800000	5
165594	2026-05-11 01:48:17.922798+00	\\xb827ebfffea04db6	916800000	5
165595	2026-05-11 02:48:13.475153+00	\\xb827ebfffe158993	916800000	5
165596	2026-05-11 02:48:14.495281+00	\\xb827ebfffef81e69	916800000	5
165597	2026-05-11 02:48:15.510419+00	\\xb827ebfffe78ffce	916800000	5
165598	2026-05-11 02:48:16.520207+00	\\xe45f01fffe10e12e	916800000	5
165599	2026-05-11 02:48:17.529882+00	\\xa840411b7dcc4150	916800000	5
165600	2026-05-11 02:48:18.540795+00	\\xb827ebfffea04db6	916800000	5
165601	2026-05-11 03:48:14.310995+00	\\xb827ebfffe158993	916800000	5
165602	2026-05-11 03:48:15.328934+00	\\xb827ebfffef81e69	916800000	5
165603	2026-05-11 03:48:16.341487+00	\\xb827ebfffe78ffce	916800000	5
165604	2026-05-11 03:48:17.365804+00	\\xe45f01fffe10e12e	916800000	5
165605	2026-05-11 03:48:18.376705+00	\\xa840411b7dcc4150	916800000	5
165606	2026-05-11 03:48:19.388215+00	\\xb827ebfffea04db6	916800000	5
165607	2026-05-11 04:48:14.985071+00	\\xb827ebfffe158993	916800000	5
165608	2026-05-11 04:48:16.007251+00	\\xb827ebfffef81e69	916800000	5
165609	2026-05-11 04:48:17.025662+00	\\xb827ebfffe78ffce	916800000	5
165610	2026-05-11 04:48:18.046402+00	\\xe45f01fffe10e12e	916800000	5
165611	2026-05-11 04:48:19.062431+00	\\xa840411b7dcc4150	916800000	5
165612	2026-05-11 04:48:20.072667+00	\\xb827ebfffea04db6	916800000	5
165613	2026-05-11 05:48:15.479804+00	\\xb827ebfffe158993	916800000	5
165614	2026-05-11 05:48:16.499157+00	\\xb827ebfffef81e69	916800000	5
165615	2026-05-11 05:48:17.508287+00	\\xb827ebfffe78ffce	916800000	5
165616	2026-05-11 05:48:18.517863+00	\\xe45f01fffe10e12e	916800000	5
165617	2026-05-11 05:48:19.528072+00	\\xa840411b7dcc4150	916800000	5
165618	2026-05-11 05:48:20.537501+00	\\xb827ebfffea04db6	916800000	5
165774	2026-05-12 07:48:33.911584+00	\\xb827ebfffea04db6	916800000	5
165775	2026-05-12 08:48:29.001804+00	\\xb827ebfffe158993	916800000	5
165776	2026-05-12 08:48:30.019271+00	\\xb827ebfffef81e69	916800000	5
165777	2026-05-12 08:48:31.037303+00	\\xb827ebfffe78ffce	916800000	5
165778	2026-05-12 08:48:32.05477+00	\\xe45f01fffe10e12e	916800000	5
165779	2026-05-12 08:48:33.067527+00	\\xa840411b7dcc4150	916800000	5
165780	2026-05-12 08:48:34.078961+00	\\xb827ebfffea04db6	916800000	5
165823	2026-05-12 16:48:33.131953+00	\\xb827ebfffe158993	916800000	5
165824	2026-05-12 16:48:34.150005+00	\\xb827ebfffef81e69	916800000	5
165825	2026-05-12 16:48:35.158893+00	\\xb827ebfffe78ffce	916800000	5
165826	2026-05-12 16:48:36.168901+00	\\xe45f01fffe10e12e	916800000	5
165827	2026-05-12 16:48:37.178403+00	\\xa840411b7dcc4150	916800000	5
165828	2026-05-12 16:48:38.187546+00	\\xb827ebfffea04db6	916800000	5
165829	2026-05-12 17:48:33.877617+00	\\xb827ebfffe158993	916800000	5
165830	2026-05-12 17:48:34.897499+00	\\xb827ebfffef81e69	916800000	5
165831	2026-05-12 17:48:35.906366+00	\\xb827ebfffe78ffce	916800000	5
165832	2026-05-12 17:48:36.915834+00	\\xe45f01fffe10e12e	916800000	5
165833	2026-05-12 17:48:37.925196+00	\\xa840411b7dcc4150	916800000	5
165834	2026-05-12 17:48:38.934726+00	\\xb827ebfffea04db6	916800000	5
165835	2026-05-12 18:48:34.132681+00	\\xb827ebfffe158993	916800000	5
165836	2026-05-12 18:48:35.151078+00	\\xb827ebfffef81e69	916800000	5
165837	2026-05-12 18:48:36.16037+00	\\xb827ebfffe78ffce	916800000	5
165838	2026-05-12 18:48:37.169773+00	\\xe45f01fffe10e12e	916800000	5
165839	2026-05-12 18:48:38.181774+00	\\xa840411b7dcc4150	916800000	5
165840	2026-05-12 18:48:39.194485+00	\\xb827ebfffea04db6	916800000	5
165841	2026-05-12 19:48:34.517673+00	\\xb827ebfffe158993	916800000	5
165842	2026-05-12 19:48:35.537806+00	\\xb827ebfffef81e69	916800000	5
165843	2026-05-12 19:48:36.548686+00	\\xb827ebfffe78ffce	916800000	5
165844	2026-05-12 19:48:37.558774+00	\\xe45f01fffe10e12e	916800000	5
165845	2026-05-12 19:48:38.568024+00	\\xa840411b7dcc4150	916800000	5
165846	2026-05-12 19:48:39.576871+00	\\xb827ebfffea04db6	916800000	5
165847	2026-05-12 20:48:34.941105+00	\\xb827ebfffe158993	916800000	5
165848	2026-05-12 20:48:35.962135+00	\\xb827ebfffef81e69	916800000	5
165849	2026-05-12 20:48:36.97081+00	\\xb827ebfffe78ffce	916800000	5
165850	2026-05-12 20:48:37.981263+00	\\xe45f01fffe10e12e	916800000	5
165851	2026-05-12 20:48:38.992811+00	\\xa840411b7dcc4150	916800000	5
165619	2026-05-11 06:48:16.156517+00	\\xb827ebfffe158993	916800000	5
165620	2026-05-11 06:48:17.177262+00	\\xb827ebfffef81e69	916800000	5
165621	2026-05-11 06:48:18.189164+00	\\xb827ebfffe78ffce	916800000	5
165622	2026-05-11 06:48:19.200577+00	\\xe45f01fffe10e12e	916800000	5
165623	2026-05-11 06:48:20.211122+00	\\xa840411b7dcc4150	916800000	5
165624	2026-05-11 06:48:21.222194+00	\\xb827ebfffea04db6	916800000	5
165625	2026-05-11 07:48:16.283476+00	\\xb827ebfffe158993	916800000	5
165626	2026-05-11 07:48:17.30326+00	\\xb827ebfffef81e69	916800000	5
165627	2026-05-11 07:48:18.313153+00	\\xb827ebfffe78ffce	916800000	5
165628	2026-05-11 07:48:19.323145+00	\\xe45f01fffe10e12e	916800000	5
165629	2026-05-11 07:48:20.335581+00	\\xa840411b7dcc4150	916800000	5
165630	2026-05-11 07:48:21.345105+00	\\xb827ebfffea04db6	916800000	5
165631	2026-05-11 08:48:17.266113+00	\\xb827ebfffe158993	916800000	5
165632	2026-05-11 08:48:18.285667+00	\\xb827ebfffef81e69	916800000	5
165633	2026-05-11 08:48:19.295267+00	\\xb827ebfffe78ffce	916800000	5
165634	2026-05-11 08:48:20.3053+00	\\xe45f01fffe10e12e	916800000	5
165635	2026-05-11 08:48:21.316231+00	\\xa840411b7dcc4150	916800000	5
165636	2026-05-11 08:48:22.330955+00	\\xb827ebfffea04db6	916800000	5
165637	2026-05-11 09:48:17.473362+00	\\xb827ebfffe158993	916800000	5
165638	2026-05-11 09:48:18.491093+00	\\xb827ebfffef81e69	916800000	5
165639	2026-05-11 09:48:19.503418+00	\\xb827ebfffe78ffce	916800000	5
165640	2026-05-11 09:48:20.51392+00	\\xe45f01fffe10e12e	916800000	5
165641	2026-05-11 09:48:21.524731+00	\\xa840411b7dcc4150	916800000	5
165642	2026-05-11 09:48:22.535465+00	\\xb827ebfffea04db6	916800000	5
165643	2026-05-11 10:48:17.668647+00	\\xb827ebfffe158993	916800000	5
165644	2026-05-11 10:48:18.686707+00	\\xb827ebfffef81e69	916800000	5
165645	2026-05-11 10:48:19.695995+00	\\xb827ebfffe78ffce	916800000	5
165646	2026-05-11 10:48:20.707075+00	\\xe45f01fffe10e12e	916800000	5
165647	2026-05-11 10:48:21.719337+00	\\xa840411b7dcc4150	916800000	5
165648	2026-05-11 10:48:22.741354+00	\\xb827ebfffea04db6	916800000	5
165649	2026-05-11 11:48:18.269046+00	\\xb827ebfffe158993	916800000	5
165650	2026-05-11 11:48:19.28986+00	\\xb827ebfffef81e69	916800000	5
165651	2026-05-11 11:48:20.299206+00	\\xb827ebfffe78ffce	916800000	5
165652	2026-05-11 11:48:21.309034+00	\\xe45f01fffe10e12e	916800000	5
165653	2026-05-11 11:48:22.318867+00	\\xa840411b7dcc4150	916800000	5
165654	2026-05-11 11:48:23.329313+00	\\xb827ebfffea04db6	916800000	5
165655	2026-05-11 12:48:18.749639+00	\\xb827ebfffe158993	916800000	5
165656	2026-05-11 12:48:19.770785+00	\\xb827ebfffef81e69	916800000	5
165657	2026-05-11 12:48:20.785509+00	\\xb827ebfffe78ffce	916800000	5
165658	2026-05-11 12:48:21.80223+00	\\xe45f01fffe10e12e	916800000	5
165659	2026-05-11 12:48:22.811539+00	\\xa840411b7dcc4150	916800000	5
165660	2026-05-11 12:48:23.821349+00	\\xb827ebfffea04db6	916800000	5
165661	2026-05-11 13:48:19.262976+00	\\xb827ebfffe158993	916800000	5
165662	2026-05-11 13:48:20.286225+00	\\xb827ebfffef81e69	916800000	5
165663	2026-05-11 13:48:21.297598+00	\\xb827ebfffe78ffce	916800000	5
165664	2026-05-11 13:48:22.31113+00	\\xe45f01fffe10e12e	916800000	5
165665	2026-05-11 13:48:23.320827+00	\\xa840411b7dcc4150	916800000	5
165666	2026-05-11 13:48:24.331563+00	\\xb827ebfffea04db6	916800000	5
165667	2026-05-11 14:48:19.962258+00	\\xb827ebfffe158993	916800000	5
165668	2026-05-11 14:48:20.97869+00	\\xb827ebfffef81e69	916800000	5
165523	2026-05-10 14:48:08.156916+00	\\xb827ebfffe158993	916800000	5
165524	2026-05-10 14:48:09.206454+00	\\xb827ebfffef81e69	916800000	5
165525	2026-05-10 14:48:10.216878+00	\\xb827ebfffe78ffce	916800000	5
165526	2026-05-10 14:48:11.229191+00	\\xe45f01fffe10e12e	916800000	5
165527	2026-05-10 14:48:12.240617+00	\\xa840411b7dcc4150	916800000	5
165528	2026-05-10 14:48:13.249941+00	\\xb827ebfffea04db6	916800000	5
165669	2026-05-11 14:48:21.990219+00	\\xb827ebfffe78ffce	916800000	5
165670	2026-05-11 14:48:23.008234+00	\\xe45f01fffe10e12e	916800000	5
165671	2026-05-11 14:48:24.018989+00	\\xa840411b7dcc4150	916800000	5
165672	2026-05-11 14:48:25.029618+00	\\xb827ebfffea04db6	916800000	5
165673	2026-05-11 15:48:20.433046+00	\\xb827ebfffe158993	916800000	5
165674	2026-05-11 15:48:21.455728+00	\\xb827ebfffef81e69	916800000	5
165675	2026-05-11 15:48:22.470581+00	\\xb827ebfffe78ffce	916800000	5
165676	2026-05-11 15:48:23.484558+00	\\xe45f01fffe10e12e	916800000	5
165677	2026-05-11 15:48:24.495811+00	\\xa840411b7dcc4150	916800000	5
165678	2026-05-11 15:48:25.505525+00	\\xb827ebfffea04db6	916800000	5
165679	2026-05-11 16:48:20.476438+00	\\xb827ebfffe158993	916800000	5
165680	2026-05-11 16:48:21.497207+00	\\xb827ebfffef81e69	916800000	5
165681	2026-05-11 16:48:22.513637+00	\\xb827ebfffe78ffce	916800000	5
165682	2026-05-11 16:48:23.523236+00	\\xe45f01fffe10e12e	916800000	5
165683	2026-05-11 16:48:24.533664+00	\\xa840411b7dcc4150	916800000	5
165684	2026-05-11 16:48:25.545223+00	\\xb827ebfffea04db6	916800000	5
165685	2026-05-11 17:48:21.485656+00	\\xb827ebfffe158993	916800000	5
165686	2026-05-11 17:48:22.520653+00	\\xb827ebfffef81e69	916800000	5
165687	2026-05-11 17:48:23.53729+00	\\xb827ebfffe78ffce	916800000	5
165688	2026-05-11 17:48:24.546952+00	\\xe45f01fffe10e12e	916800000	5
165689	2026-05-11 17:48:25.557705+00	\\xa840411b7dcc4150	916800000	5
165690	2026-05-11 17:48:26.57132+00	\\xb827ebfffea04db6	916800000	5
165781	2026-05-12 09:48:29.312579+00	\\xb827ebfffe158993	916800000	5
165782	2026-05-12 09:48:30.331225+00	\\xb827ebfffef81e69	916800000	5
165783	2026-05-12 09:48:31.340461+00	\\xb827ebfffe78ffce	916800000	5
165784	2026-05-12 09:48:32.350672+00	\\xe45f01fffe10e12e	916800000	5
165785	2026-05-12 09:48:33.360079+00	\\xa840411b7dcc4150	916800000	5
165786	2026-05-12 09:48:34.370014+00	\\xb827ebfffea04db6	916800000	5
165787	2026-05-12 10:48:29.341811+00	\\xb827ebfffe158993	916800000	5
165788	2026-05-12 10:48:30.362177+00	\\xb827ebfffef81e69	916800000	5
165789	2026-05-12 10:48:31.375442+00	\\xb827ebfffe78ffce	916800000	5
165790	2026-05-12 10:48:32.387601+00	\\xe45f01fffe10e12e	916800000	5
165791	2026-05-12 10:48:33.399375+00	\\xa840411b7dcc4150	916800000	5
165792	2026-05-12 10:48:34.409989+00	\\xb827ebfffea04db6	916800000	5
165793	2026-05-12 11:48:30.352659+00	\\xb827ebfffe158993	916800000	5
165794	2026-05-12 11:48:31.373852+00	\\xb827ebfffef81e69	916800000	5
165795	2026-05-12 11:48:32.385168+00	\\xb827ebfffe78ffce	916800000	5
165796	2026-05-12 11:48:33.397404+00	\\xe45f01fffe10e12e	916800000	5
165797	2026-05-12 11:48:34.409001+00	\\xa840411b7dcc4150	916800000	5
165798	2026-05-12 11:48:35.418514+00	\\xb827ebfffea04db6	916800000	5
165799	2026-05-12 12:48:31.281895+00	\\xb827ebfffe158993	916800000	5
165800	2026-05-12 12:48:32.302732+00	\\xb827ebfffef81e69	916800000	5
165801	2026-05-12 12:48:33.313735+00	\\xb827ebfffe78ffce	916800000	5
165802	2026-05-12 12:48:34.323885+00	\\xe45f01fffe10e12e	916800000	5
165803	2026-05-12 12:48:35.4857+00	\\xa840411b7dcc4150	916800000	5
165804	2026-05-12 12:48:36.495444+00	\\xb827ebfffea04db6	916800000	5
165805	2026-05-12 13:48:31.913126+00	\\xb827ebfffe158993	916800000	5
165806	2026-05-12 13:48:32.930253+00	\\xb827ebfffef81e69	916800000	5
165807	2026-05-12 13:48:33.940613+00	\\xb827ebfffe78ffce	916800000	5
165808	2026-05-12 13:48:34.950881+00	\\xe45f01fffe10e12e	916800000	5
165809	2026-05-12 13:48:35.96261+00	\\xa840411b7dcc4150	916800000	5
165810	2026-05-12 13:48:36.974472+00	\\xb827ebfffea04db6	916800000	5
165811	2026-05-12 14:48:32.469137+00	\\xb827ebfffe158993	916800000	5
165812	2026-05-12 14:48:33.49566+00	\\xb827ebfffef81e69	916800000	5
165813	2026-05-12 14:48:34.505881+00	\\xb827ebfffe78ffce	916800000	5
165814	2026-05-12 14:48:35.515577+00	\\xe45f01fffe10e12e	916800000	5
165815	2026-05-12 14:48:36.525161+00	\\xa840411b7dcc4150	916800000	5
165816	2026-05-12 14:48:37.534712+00	\\xb827ebfffea04db6	916800000	5
165817	2026-05-12 15:48:32.786635+00	\\xb827ebfffe158993	916800000	5
165818	2026-05-12 15:48:33.806575+00	\\xb827ebfffef81e69	916800000	5
165819	2026-05-12 15:48:34.816448+00	\\xb827ebfffe78ffce	916800000	5
165820	2026-05-12 15:48:35.825997+00	\\xe45f01fffe10e12e	916800000	5
165821	2026-05-12 15:48:36.835006+00	\\xa840411b7dcc4150	916800000	5
165822	2026-05-12 15:48:37.844118+00	\\xb827ebfffea04db6	916800000	5
165852	2026-05-12 20:48:40.004345+00	\\xb827ebfffea04db6	916800000	5
165853	2026-05-12 21:48:35.394643+00	\\xb827ebfffe158993	916800000	5
165854	2026-05-12 21:48:36.411662+00	\\xb827ebfffef81e69	916800000	5
165855	2026-05-12 21:48:37.42106+00	\\xb827ebfffe78ffce	916800000	5
165856	2026-05-12 21:48:38.430976+00	\\xe45f01fffe10e12e	916800000	5
165857	2026-05-12 21:48:39.441067+00	\\xa840411b7dcc4150	916800000	5
165858	2026-05-12 21:48:40.452879+00	\\xb827ebfffea04db6	916800000	5
165859	2026-05-12 22:48:35.413967+00	\\xb827ebfffe158993	916800000	5
165860	2026-05-12 22:48:36.431881+00	\\xb827ebfffef81e69	916800000	5
165861	2026-05-12 22:48:37.442023+00	\\xb827ebfffe78ffce	916800000	5
165862	2026-05-12 22:48:38.45215+00	\\xe45f01fffe10e12e	916800000	5
165863	2026-05-12 22:48:39.461376+00	\\xa840411b7dcc4150	916800000	5
165864	2026-05-12 22:48:40.470932+00	\\xb827ebfffea04db6	916800000	5
165865	2026-05-12 23:48:35.945126+00	\\xb827ebfffe158993	916800000	5
165866	2026-05-12 23:48:36.97108+00	\\xb827ebfffef81e69	916800000	5
165867	2026-05-12 23:48:37.980999+00	\\xb827ebfffe78ffce	916800000	5
165868	2026-05-12 23:48:38.990697+00	\\xe45f01fffe10e12e	916800000	5
165869	2026-05-12 23:48:39.99969+00	\\xa840411b7dcc4150	916800000	5
165870	2026-05-12 23:48:41.009007+00	\\xb827ebfffea04db6	916800000	5
165871	2026-05-13 00:48:36.339007+00	\\xb827ebfffe158993	916800000	5
165872	2026-05-13 00:48:37.35566+00	\\xb827ebfffef81e69	916800000	5
165873	2026-05-13 00:48:38.36446+00	\\xb827ebfffe78ffce	916800000	5
165874	2026-05-13 00:48:39.37385+00	\\xe45f01fffe10e12e	916800000	5
165875	2026-05-13 00:48:40.382923+00	\\xa840411b7dcc4150	916800000	5
165876	2026-05-13 00:48:41.395102+00	\\xb827ebfffea04db6	916800000	5
165877	2026-05-13 01:48:36.45461+00	\\xb827ebfffe158993	916800000	5
165878	2026-05-13 01:48:37.474099+00	\\xb827ebfffef81e69	916800000	5
165879	2026-05-13 01:48:38.48328+00	\\xb827ebfffe78ffce	916800000	5
165880	2026-05-13 01:48:39.492815+00	\\xe45f01fffe10e12e	916800000	5
165881	2026-05-13 01:48:40.501473+00	\\xa840411b7dcc4150	916800000	5
165882	2026-05-13 01:48:41.515383+00	\\xb827ebfffea04db6	916800000	5
165883	2026-05-13 02:48:36.706873+00	\\xb827ebfffe158993	916800000	5
165884	2026-05-13 02:48:37.723356+00	\\xb827ebfffef81e69	916800000	5
165885	2026-05-13 02:48:38.733013+00	\\xb827ebfffe78ffce	916800000	5
165886	2026-05-13 02:48:39.743216+00	\\xe45f01fffe10e12e	916800000	5
165887	2026-05-13 02:48:40.75449+00	\\xa840411b7dcc4150	916800000	5
165888	2026-05-13 02:48:41.767702+00	\\xb827ebfffea04db6	916800000	5
165889	2026-05-13 03:48:37.28628+00	\\xb827ebfffe158993	916800000	5
165890	2026-05-13 03:48:38.302986+00	\\xb827ebfffef81e69	916800000	5
165891	2026-05-13 03:48:39.312902+00	\\xb827ebfffe78ffce	916800000	5
165892	2026-05-13 03:48:40.329654+00	\\xe45f01fffe10e12e	916800000	5
165893	2026-05-13 03:48:41.338737+00	\\xa840411b7dcc4150	916800000	5
165894	2026-05-13 03:48:42.351492+00	\\xb827ebfffea04db6	916800000	5
165895	2026-05-13 04:48:37.729115+00	\\xb827ebfffe158993	916800000	5
165896	2026-05-13 04:48:38.75032+00	\\xb827ebfffef81e69	916800000	5
165897	2026-05-13 04:48:39.759777+00	\\xb827ebfffe78ffce	916800000	5
165898	2026-05-13 04:48:40.773994+00	\\xe45f01fffe10e12e	916800000	5
165899	2026-05-13 04:48:41.790316+00	\\xa840411b7dcc4150	916800000	5
165900	2026-05-13 04:48:42.799359+00	\\xb827ebfffea04db6	916800000	5
165901	2026-05-13 05:48:38.269342+00	\\xb827ebfffe158993	916800000	5
165902	2026-05-13 05:48:39.287389+00	\\xb827ebfffef81e69	916800000	5
165903	2026-05-13 05:48:40.297158+00	\\xb827ebfffe78ffce	916800000	5
165904	2026-05-13 05:48:41.306759+00	\\xe45f01fffe10e12e	916800000	5
165905	2026-05-13 05:48:42.316602+00	\\xa840411b7dcc4150	916800000	5
165906	2026-05-13 05:48:43.32557+00	\\xb827ebfffea04db6	916800000	5
165907	2026-05-13 06:48:38.498857+00	\\xb827ebfffe158993	916800000	5
165908	2026-05-13 06:48:39.514373+00	\\xb827ebfffef81e69	916800000	5
165909	2026-05-13 06:48:40.523289+00	\\xb827ebfffe78ffce	916800000	5
165910	2026-05-13 06:48:41.532882+00	\\xe45f01fffe10e12e	916800000	5
165911	2026-05-13 06:48:42.545068+00	\\xa840411b7dcc4150	916800000	5
165912	2026-05-13 06:48:43.555852+00	\\xb827ebfffea04db6	916800000	5
165913	2026-05-13 07:48:39.022578+00	\\xb827ebfffe158993	916800000	5
165914	2026-05-13 07:48:40.040583+00	\\xb827ebfffef81e69	916800000	5
165915	2026-05-13 07:48:41.054616+00	\\xb827ebfffe78ffce	916800000	5
165916	2026-05-13 07:48:42.066566+00	\\xe45f01fffe10e12e	916800000	5
165917	2026-05-13 07:48:43.075562+00	\\xa840411b7dcc4150	916800000	5
165918	2026-05-13 07:48:44.085378+00	\\xb827ebfffea04db6	916800000	5
165919	2026-05-13 08:48:39.977558+00	\\xb827ebfffe158993	916800000	5
165920	2026-05-13 08:48:40.993798+00	\\xb827ebfffef81e69	916800000	5
165921	2026-05-13 08:48:42.003037+00	\\xb827ebfffe78ffce	916800000	5
165922	2026-05-13 08:48:43.012522+00	\\xe45f01fffe10e12e	916800000	5
165923	2026-05-13 08:48:44.034806+00	\\xa840411b7dcc4150	916800000	5
165924	2026-05-13 08:48:45.044106+00	\\xb827ebfffea04db6	916800000	5
165925	2026-05-13 09:48:40.108725+00	\\xb827ebfffe158993	916800000	5
165926	2026-05-13 09:48:41.12534+00	\\xb827ebfffef81e69	916800000	5
165927	2026-05-13 09:48:42.134284+00	\\xb827ebfffe78ffce	916800000	5
165928	2026-05-13 09:48:43.143278+00	\\xe45f01fffe10e12e	916800000	5
165929	2026-05-13 09:48:44.15671+00	\\xa840411b7dcc4150	916800000	5
165930	2026-05-13 09:48:45.166109+00	\\xb827ebfffea04db6	916800000	5
165931	2026-05-13 10:48:40.35097+00	\\xb827ebfffe158993	916800000	5
165932	2026-05-13 10:48:41.372871+00	\\xb827ebfffef81e69	916800000	5
165933	2026-05-13 10:48:42.386155+00	\\xb827ebfffe78ffce	916800000	5
165934	2026-05-13 10:48:43.397795+00	\\xe45f01fffe10e12e	916800000	5
165935	2026-05-13 10:48:44.407467+00	\\xa840411b7dcc4150	916800000	5
165936	2026-05-13 10:48:45.416977+00	\\xb827ebfffea04db6	916800000	5
165937	2026-05-13 11:48:40.728812+00	\\xb827ebfffe158993	916800000	5
165938	2026-05-13 11:48:41.759083+00	\\xb827ebfffef81e69	916800000	5
165939	2026-05-13 11:48:42.768989+00	\\xb827ebfffe78ffce	916800000	5
165940	2026-05-13 11:48:43.781805+00	\\xe45f01fffe10e12e	916800000	5
165941	2026-05-13 11:48:44.791654+00	\\xa840411b7dcc4150	916800000	5
165942	2026-05-13 11:48:45.800944+00	\\xb827ebfffea04db6	916800000	5
165943	2026-05-13 12:48:41.173518+00	\\xb827ebfffe158993	916800000	5
165944	2026-05-13 12:48:42.197734+00	\\xb827ebfffef81e69	916800000	5
165945	2026-05-13 12:48:43.224239+00	\\xb827ebfffe78ffce	916800000	5
165946	2026-05-13 12:48:44.236742+00	\\xe45f01fffe10e12e	916800000	5
165947	2026-05-13 12:48:45.247016+00	\\xa840411b7dcc4150	916800000	5
165948	2026-05-13 12:48:46.256858+00	\\xb827ebfffea04db6	916800000	5
165949	2026-05-13 13:48:41.345262+00	\\xb827ebfffe158993	916800000	5
165950	2026-05-13 13:48:42.368386+00	\\xb827ebfffef81e69	916800000	5
165951	2026-05-13 13:48:43.378458+00	\\xb827ebfffe78ffce	916800000	5
165952	2026-05-13 13:48:44.389092+00	\\xe45f01fffe10e12e	916800000	5
165953	2026-05-13 13:48:45.398066+00	\\xa840411b7dcc4150	916800000	5
165954	2026-05-13 13:48:46.408647+00	\\xb827ebfffea04db6	916800000	5
165955	2026-05-13 14:48:41.835719+00	\\xb827ebfffe158993	916800000	5
165956	2026-05-13 14:48:42.867238+00	\\xb827ebfffef81e69	916800000	5
165957	2026-05-13 14:48:43.880645+00	\\xb827ebfffe78ffce	916800000	5
165958	2026-05-13 14:48:44.890615+00	\\xe45f01fffe10e12e	916800000	5
165959	2026-05-13 14:48:45.900121+00	\\xa840411b7dcc4150	916800000	5
165960	2026-05-13 14:48:46.912333+00	\\xb827ebfffea04db6	916800000	5
165961	2026-05-13 15:48:41.951638+00	\\xb827ebfffe158993	916800000	5
165962	2026-05-13 15:48:42.973921+00	\\xb827ebfffef81e69	916800000	5
165963	2026-05-13 15:48:43.99954+00	\\xb827ebfffe78ffce	916800000	5
165964	2026-05-13 15:48:45.010999+00	\\xe45f01fffe10e12e	916800000	5
165965	2026-05-13 15:48:46.020476+00	\\xa840411b7dcc4150	916800000	5
165966	2026-05-13 15:48:47.030132+00	\\xb827ebfffea04db6	916800000	5
165967	2026-05-13 16:48:42.403908+00	\\xb827ebfffe158993	916800000	5
165968	2026-05-13 16:48:43.444755+00	\\xb827ebfffef81e69	916800000	5
165969	2026-05-13 16:48:44.4567+00	\\xb827ebfffe78ffce	916800000	5
165970	2026-05-13 16:48:45.467161+00	\\xe45f01fffe10e12e	916800000	5
165971	2026-05-13 16:48:46.478215+00	\\xa840411b7dcc4150	916800000	5
165972	2026-05-13 16:48:47.487558+00	\\xb827ebfffea04db6	916800000	5
165973	2026-05-13 17:48:42.76136+00	\\xb827ebfffe158993	916800000	5
165974	2026-05-13 17:48:43.789078+00	\\xb827ebfffef81e69	916800000	5
165975	2026-05-13 17:48:44.799329+00	\\xb827ebfffe78ffce	916800000	5
165976	2026-05-13 17:48:45.810087+00	\\xe45f01fffe10e12e	916800000	5
165977	2026-05-13 17:48:46.824118+00	\\xa840411b7dcc4150	916800000	5
165978	2026-05-13 17:48:47.834363+00	\\xb827ebfffea04db6	916800000	5
165979	2026-05-13 18:48:43.704329+00	\\xb827ebfffe158993	916800000	5
165980	2026-05-13 18:48:44.725832+00	\\xb827ebfffef81e69	916800000	5
165981	2026-05-13 18:48:45.735836+00	\\xb827ebfffe78ffce	916800000	5
165982	2026-05-13 18:48:46.745162+00	\\xe45f01fffe10e12e	916800000	5
165983	2026-05-13 18:48:47.754752+00	\\xa840411b7dcc4150	916800000	5
165984	2026-05-13 18:48:48.76487+00	\\xb827ebfffea04db6	916800000	5
165985	2026-05-13 19:48:44.218909+00	\\xb827ebfffe158993	916800000	5
165986	2026-05-13 19:48:45.235359+00	\\xb827ebfffef81e69	916800000	5
165987	2026-05-13 19:48:46.244607+00	\\xb827ebfffe78ffce	916800000	5
165988	2026-05-13 19:48:47.254222+00	\\xe45f01fffe10e12e	916800000	5
165989	2026-05-13 19:48:48.266364+00	\\xa840411b7dcc4150	916800000	5
165990	2026-05-13 19:48:49.276252+00	\\xb827ebfffea04db6	916800000	5
165991	2026-05-13 20:48:44.554841+00	\\xb827ebfffe158993	916800000	5
165992	2026-05-13 20:48:45.574891+00	\\xb827ebfffef81e69	916800000	5
165993	2026-05-13 20:48:46.585041+00	\\xb827ebfffe78ffce	916800000	5
165994	2026-05-13 20:48:47.594774+00	\\xe45f01fffe10e12e	916800000	5
165995	2026-05-13 20:48:48.603757+00	\\xa840411b7dcc4150	916800000	5
165996	2026-05-13 20:48:49.613265+00	\\xb827ebfffea04db6	916800000	5
165997	2026-05-13 21:48:44.568235+00	\\xb827ebfffe158993	916800000	5
165998	2026-05-13 21:48:45.588271+00	\\xb827ebfffef81e69	916800000	5
165999	2026-05-13 21:48:46.597374+00	\\xb827ebfffe78ffce	916800000	5
166000	2026-05-13 21:48:47.607748+00	\\xe45f01fffe10e12e	916800000	5
166001	2026-05-13 21:48:48.618558+00	\\xa840411b7dcc4150	916800000	5
166002	2026-05-13 21:48:49.628718+00	\\xb827ebfffea04db6	916800000	5
166003	2026-05-13 22:48:44.638286+00	\\xb827ebfffe158993	916800000	5
166004	2026-05-13 22:48:45.654549+00	\\xb827ebfffef81e69	916800000	5
166005	2026-05-13 22:48:46.665065+00	\\xb827ebfffe78ffce	916800000	5
166006	2026-05-13 22:48:47.675208+00	\\xe45f01fffe10e12e	916800000	5
166007	2026-05-13 22:48:48.684692+00	\\xa840411b7dcc4150	916800000	5
166008	2026-05-13 22:48:49.694174+00	\\xb827ebfffea04db6	916800000	5
166009	2026-05-13 23:48:45.198474+00	\\xb827ebfffe158993	916800000	5
166010	2026-05-13 23:48:46.227939+00	\\xb827ebfffef81e69	916800000	5
166011	2026-05-13 23:48:47.237691+00	\\xb827ebfffe78ffce	916800000	5
166012	2026-05-13 23:48:48.24777+00	\\xe45f01fffe10e12e	916800000	5
166013	2026-05-13 23:48:49.25871+00	\\xa840411b7dcc4150	916800000	5
166014	2026-05-13 23:48:50.269593+00	\\xb827ebfffea04db6	916800000	5
166015	2026-05-14 00:48:45.235961+00	\\xb827ebfffe158993	916800000	5
166016	2026-05-14 00:48:46.251662+00	\\xb827ebfffef81e69	916800000	5
166017	2026-05-14 00:48:47.261329+00	\\xb827ebfffe78ffce	916800000	5
166018	2026-05-14 00:48:48.272187+00	\\xe45f01fffe10e12e	916800000	5
166019	2026-05-14 00:48:49.282753+00	\\xa840411b7dcc4150	916800000	5
166020	2026-05-14 00:48:50.29267+00	\\xb827ebfffea04db6	916800000	5
166021	2026-05-14 01:48:45.366727+00	\\xb827ebfffe158993	916800000	5
166022	2026-05-14 01:48:46.384419+00	\\xb827ebfffef81e69	916800000	5
166023	2026-05-14 01:48:47.395653+00	\\xb827ebfffe78ffce	916800000	5
166024	2026-05-14 01:48:48.40795+00	\\xe45f01fffe10e12e	916800000	5
166025	2026-05-14 01:48:49.418349+00	\\xa840411b7dcc4150	916800000	5
166026	2026-05-14 01:48:50.428137+00	\\xb827ebfffea04db6	916800000	5
166027	2026-05-14 02:48:45.804889+00	\\xb827ebfffe158993	916800000	5
166028	2026-05-14 02:48:46.823264+00	\\xb827ebfffef81e69	916800000	5
166029	2026-05-14 02:48:47.835509+00	\\xb827ebfffe78ffce	916800000	5
166030	2026-05-14 02:48:48.845334+00	\\xe45f01fffe10e12e	916800000	5
166031	2026-05-14 02:48:49.854971+00	\\xa840411b7dcc4150	916800000	5
166032	2026-05-14 02:48:50.870511+00	\\xb827ebfffea04db6	916800000	5
166033	2026-05-14 03:48:46.472389+00	\\xb827ebfffe158993	916800000	5
166034	2026-05-14 03:48:47.491271+00	\\xb827ebfffef81e69	916800000	5
166035	2026-05-14 03:48:48.500241+00	\\xb827ebfffe78ffce	916800000	5
166036	2026-05-14 03:48:49.510305+00	\\xe45f01fffe10e12e	916800000	5
166037	2026-05-14 03:48:50.521961+00	\\xa840411b7dcc4150	916800000	5
166038	2026-05-14 03:48:51.532515+00	\\xb827ebfffea04db6	916800000	5
166039	2026-05-14 04:48:47.253053+00	\\xb827ebfffe158993	916800000	5
166040	2026-05-14 04:48:48.276046+00	\\xb827ebfffef81e69	916800000	5
166041	2026-05-14 04:48:49.28805+00	\\xb827ebfffe78ffce	916800000	5
166042	2026-05-14 04:48:50.298917+00	\\xe45f01fffe10e12e	916800000	5
166043	2026-05-14 04:48:51.309602+00	\\xa840411b7dcc4150	916800000	5
166044	2026-05-14 04:48:52.319274+00	\\xb827ebfffea04db6	916800000	5
166045	2026-05-14 05:48:47.529563+00	\\xb827ebfffe158993	916800000	5
166046	2026-05-14 05:48:48.548874+00	\\xb827ebfffef81e69	916800000	5
166047	2026-05-14 05:48:49.559302+00	\\xb827ebfffe78ffce	916800000	5
166048	2026-05-14 05:48:50.569873+00	\\xe45f01fffe10e12e	916800000	5
166049	2026-05-14 05:48:51.580556+00	\\xa840411b7dcc4150	916800000	5
166050	2026-05-14 05:48:52.591598+00	\\xb827ebfffea04db6	916800000	5
166051	2026-05-14 06:48:47.804184+00	\\xb827ebfffe158993	916800000	5
166052	2026-05-14 06:48:48.822698+00	\\xb827ebfffef81e69	916800000	5
166053	2026-05-14 06:48:49.832678+00	\\xb827ebfffe78ffce	916800000	5
166054	2026-05-14 06:48:50.846301+00	\\xe45f01fffe10e12e	916800000	5
166055	2026-05-14 06:48:51.862718+00	\\xa840411b7dcc4150	916800000	5
166056	2026-05-14 06:48:52.872583+00	\\xb827ebfffea04db6	916800000	5
166057	2026-05-14 07:48:48.484394+00	\\xb827ebfffe158993	916800000	5
166058	2026-05-14 07:48:49.509014+00	\\xb827ebfffef81e69	916800000	5
166059	2026-05-14 07:48:50.518558+00	\\xb827ebfffe78ffce	916800000	5
166060	2026-05-14 07:48:51.528694+00	\\xe45f01fffe10e12e	916800000	5
166061	2026-05-14 07:48:52.539438+00	\\xa840411b7dcc4150	916800000	5
166062	2026-05-14 07:48:53.554301+00	\\xb827ebfffea04db6	916800000	5
166063	2026-05-14 08:48:49.124708+00	\\xb827ebfffe158993	916800000	5
166064	2026-05-14 08:48:50.14301+00	\\xb827ebfffef81e69	916800000	5
166065	2026-05-14 08:48:51.153593+00	\\xb827ebfffe78ffce	916800000	5
166066	2026-05-14 08:48:52.167346+00	\\xe45f01fffe10e12e	916800000	5
166067	2026-05-14 08:48:53.1822+00	\\xa840411b7dcc4150	916800000	5
166068	2026-05-14 08:48:54.194807+00	\\xb827ebfffea04db6	916800000	5
166069	2026-05-14 09:48:49.437208+00	\\xb827ebfffe158993	916800000	5
166070	2026-05-14 09:48:50.455568+00	\\xb827ebfffef81e69	916800000	5
166071	2026-05-14 09:48:51.470433+00	\\xb827ebfffe78ffce	916800000	5
166072	2026-05-14 09:48:52.485682+00	\\xe45f01fffe10e12e	916800000	5
166073	2026-05-14 09:48:53.502513+00	\\xa840411b7dcc4150	916800000	5
166074	2026-05-14 09:48:54.512461+00	\\xb827ebfffea04db6	916800000	5
166075	2026-05-14 10:48:50.199566+00	\\xb827ebfffe158993	916800000	5
166076	2026-05-14 10:48:51.220251+00	\\xb827ebfffef81e69	916800000	5
166077	2026-05-14 10:48:52.230188+00	\\xb827ebfffe78ffce	916800000	5
166078	2026-05-14 10:48:53.243162+00	\\xe45f01fffe10e12e	916800000	5
166079	2026-05-14 10:48:54.263077+00	\\xa840411b7dcc4150	916800000	5
166080	2026-05-14 10:48:55.276984+00	\\xb827ebfffea04db6	916800000	5
166081	2026-05-14 11:48:51.129843+00	\\xb827ebfffe158993	916800000	5
166082	2026-05-14 11:48:52.147349+00	\\xb827ebfffef81e69	916800000	5
166083	2026-05-14 11:48:53.160907+00	\\xb827ebfffe78ffce	916800000	5
166084	2026-05-14 11:48:54.17655+00	\\xe45f01fffe10e12e	916800000	5
166085	2026-05-14 11:48:55.186346+00	\\xa840411b7dcc4150	916800000	5
166086	2026-05-14 11:48:56.196275+00	\\xb827ebfffea04db6	916800000	5
166087	2026-05-14 12:48:51.93676+00	\\xb827ebfffe158993	916800000	5
166088	2026-05-14 12:48:52.953392+00	\\xb827ebfffef81e69	916800000	5
166089	2026-05-14 12:48:53.969996+00	\\xb827ebfffe78ffce	916800000	5
166090	2026-05-14 12:48:54.981631+00	\\xe45f01fffe10e12e	916800000	5
166091	2026-05-14 12:48:55.991699+00	\\xa840411b7dcc4150	916800000	5
166092	2026-05-14 12:48:57.000634+00	\\xb827ebfffea04db6	916800000	5
166093	2026-05-14 13:48:52.910732+00	\\xb827ebfffe158993	916800000	5
166094	2026-05-14 13:48:53.927783+00	\\xb827ebfffef81e69	916800000	5
166095	2026-05-14 13:48:54.938011+00	\\xb827ebfffe78ffce	916800000	5
166096	2026-05-14 13:48:55.948521+00	\\xe45f01fffe10e12e	916800000	5
166097	2026-05-14 13:48:56.959339+00	\\xa840411b7dcc4150	916800000	5
166098	2026-05-14 13:48:57.968617+00	\\xb827ebfffea04db6	916800000	5
166099	2026-05-14 14:48:53.204443+00	\\xb827ebfffe158993	916800000	5
166100	2026-05-14 14:48:54.230755+00	\\xb827ebfffef81e69	916800000	5
166101	2026-05-14 14:48:55.240715+00	\\xb827ebfffe78ffce	916800000	5
166102	2026-05-14 14:48:56.253419+00	\\xe45f01fffe10e12e	916800000	5
166103	2026-05-14 14:48:57.262859+00	\\xa840411b7dcc4150	916800000	5
166104	2026-05-14 14:48:58.271962+00	\\xb827ebfffea04db6	916800000	5
166105	2026-05-14 15:48:54.196575+00	\\xb827ebfffe158993	916800000	5
166106	2026-05-14 15:48:55.212979+00	\\xb827ebfffef81e69	916800000	5
166107	2026-05-14 15:48:56.222695+00	\\xb827ebfffe78ffce	916800000	5
166108	2026-05-14 15:48:57.232976+00	\\xe45f01fffe10e12e	916800000	5
166109	2026-05-14 15:48:58.242245+00	\\xa840411b7dcc4150	916800000	5
166110	2026-05-14 15:48:59.254911+00	\\xb827ebfffea04db6	916800000	5
166111	2026-05-14 16:48:54.613676+00	\\xb827ebfffe158993	916800000	5
166112	2026-05-14 16:48:55.634863+00	\\xb827ebfffef81e69	916800000	5
166113	2026-05-14 16:48:56.644161+00	\\xb827ebfffe78ffce	916800000	5
166114	2026-05-14 16:48:57.65405+00	\\xe45f01fffe10e12e	916800000	5
166115	2026-05-14 16:48:58.663678+00	\\xa840411b7dcc4150	916800000	5
166116	2026-05-14 16:48:59.672754+00	\\xb827ebfffea04db6	916800000	5
166117	2026-05-14 17:48:54.958982+00	\\xb827ebfffe158993	916800000	5
166118	2026-05-14 17:48:55.983574+00	\\xb827ebfffef81e69	916800000	5
166119	2026-05-14 17:48:56.995963+00	\\xb827ebfffe78ffce	916800000	5
166120	2026-05-14 17:48:58.009643+00	\\xe45f01fffe10e12e	916800000	5
166121	2026-05-14 17:48:59.018556+00	\\xa840411b7dcc4150	916800000	5
166122	2026-05-14 17:49:00.028628+00	\\xb827ebfffea04db6	916800000	5
166123	2026-05-14 18:48:55.338186+00	\\xb827ebfffe158993	916800000	5
166124	2026-05-14 18:48:56.359603+00	\\xb827ebfffef81e69	916800000	5
166125	2026-05-14 18:48:57.374797+00	\\xb827ebfffe78ffce	916800000	5
166126	2026-05-14 18:48:58.384728+00	\\xe45f01fffe10e12e	916800000	5
166127	2026-05-14 18:48:59.396009+00	\\xa840411b7dcc4150	916800000	5
166128	2026-05-14 18:49:00.40565+00	\\xb827ebfffea04db6	916800000	5
166129	2026-05-14 19:48:55.943122+00	\\xb827ebfffe158993	916800000	5
166130	2026-05-14 19:48:56.962877+00	\\xb827ebfffef81e69	916800000	5
166131	2026-05-14 19:48:57.976934+00	\\xb827ebfffe78ffce	916800000	5
166132	2026-05-14 19:48:58.986723+00	\\xe45f01fffe10e12e	916800000	5
166133	2026-05-14 19:48:59.995904+00	\\xa840411b7dcc4150	916800000	5
166134	2026-05-14 19:49:01.006584+00	\\xb827ebfffea04db6	916800000	5
166135	2026-05-14 20:48:56.704001+00	\\xb827ebfffe158993	916800000	5
166136	2026-05-14 20:48:57.722721+00	\\xb827ebfffef81e69	916800000	5
166137	2026-05-14 20:48:58.732458+00	\\xb827ebfffe78ffce	916800000	5
166138	2026-05-14 20:48:59.745021+00	\\xe45f01fffe10e12e	916800000	5
166139	2026-05-14 20:49:00.75709+00	\\xa840411b7dcc4150	916800000	5
166140	2026-05-14 20:49:01.771305+00	\\xb827ebfffea04db6	916800000	5
166141	2026-05-14 21:48:57.306486+00	\\xb827ebfffe158993	916800000	5
166142	2026-05-14 21:48:58.323804+00	\\xb827ebfffef81e69	916800000	5
166143	2026-05-14 21:48:59.335661+00	\\xb827ebfffe78ffce	916800000	5
166144	2026-05-14 21:49:00.346188+00	\\xe45f01fffe10e12e	916800000	5
166145	2026-05-14 21:49:01.35914+00	\\xa840411b7dcc4150	916800000	5
166146	2026-05-14 21:49:02.375966+00	\\xb827ebfffea04db6	916800000	5
166147	2026-05-14 22:48:58.006052+00	\\xb827ebfffe158993	916800000	5
166148	2026-05-14 22:48:59.025647+00	\\xb827ebfffef81e69	916800000	5
166149	2026-05-14 22:49:00.037227+00	\\xb827ebfffe78ffce	916800000	5
166150	2026-05-14 22:49:01.053467+00	\\xe45f01fffe10e12e	916800000	5
166151	2026-05-14 22:49:02.070762+00	\\xa840411b7dcc4150	916800000	5
166152	2026-05-14 22:49:03.083836+00	\\xb827ebfffea04db6	916800000	5
166153	2026-05-14 23:48:58.491734+00	\\xb827ebfffe158993	916800000	5
166154	2026-05-14 23:48:59.511021+00	\\xb827ebfffef81e69	916800000	5
166155	2026-05-14 23:49:00.520613+00	\\xb827ebfffe78ffce	916800000	5
166156	2026-05-14 23:49:01.530124+00	\\xe45f01fffe10e12e	916800000	5
166157	2026-05-14 23:49:02.54492+00	\\xa840411b7dcc4150	916800000	5
166158	2026-05-14 23:49:03.555928+00	\\xb827ebfffea04db6	916800000	5
166159	2026-05-15 00:48:59.07514+00	\\xb827ebfffe158993	916800000	5
166160	2026-05-15 00:49:00.093702+00	\\xb827ebfffef81e69	916800000	5
166161	2026-05-15 00:49:01.107507+00	\\xb827ebfffe78ffce	916800000	5
166162	2026-05-15 00:49:02.12107+00	\\xe45f01fffe10e12e	916800000	5
166163	2026-05-15 00:49:03.132284+00	\\xa840411b7dcc4150	916800000	5
166164	2026-05-15 00:49:04.141636+00	\\xb827ebfffea04db6	916800000	5
166165	2026-05-15 01:48:59.277825+00	\\xb827ebfffe158993	916800000	5
166166	2026-05-15 01:49:00.294462+00	\\xb827ebfffef81e69	916800000	5
166167	2026-05-15 01:49:01.304647+00	\\xb827ebfffe78ffce	916800000	5
166168	2026-05-15 01:49:02.314889+00	\\xe45f01fffe10e12e	916800000	5
166169	2026-05-15 01:49:03.324692+00	\\xa840411b7dcc4150	916800000	5
166170	2026-05-15 01:49:04.335158+00	\\xb827ebfffea04db6	916800000	5
166171	2026-05-15 02:48:59.904365+00	\\xb827ebfffe158993	916800000	5
166172	2026-05-15 02:49:00.953755+00	\\xb827ebfffef81e69	916800000	5
166173	2026-05-15 02:49:01.96773+00	\\xb827ebfffe78ffce	916800000	5
166174	2026-05-15 02:49:02.978479+00	\\xe45f01fffe10e12e	916800000	5
166175	2026-05-15 02:49:03.990774+00	\\xa840411b7dcc4150	916800000	5
166176	2026-05-15 02:49:05.002705+00	\\xb827ebfffea04db6	916800000	5
166177	2026-05-15 03:49:00.11514+00	\\xb827ebfffe158993	916800000	5
166178	2026-05-15 03:49:01.139691+00	\\xb827ebfffef81e69	916800000	5
166179	2026-05-15 03:49:02.151488+00	\\xb827ebfffe78ffce	916800000	5
166180	2026-05-15 03:49:03.166625+00	\\xe45f01fffe10e12e	916800000	5
166181	2026-05-15 03:49:04.183575+00	\\xa840411b7dcc4150	916800000	5
166182	2026-05-15 03:49:05.194401+00	\\xb827ebfffea04db6	916800000	5
166183	2026-05-15 04:49:00.551575+00	\\xb827ebfffe158993	916800000	5
166184	2026-05-15 04:49:01.575744+00	\\xb827ebfffef81e69	916800000	5
166185	2026-05-15 04:49:02.590975+00	\\xb827ebfffe78ffce	916800000	5
166186	2026-05-15 04:49:03.603791+00	\\xe45f01fffe10e12e	916800000	5
166187	2026-05-15 04:49:04.613322+00	\\xa840411b7dcc4150	916800000	5
166188	2026-05-15 04:49:05.625808+00	\\xb827ebfffea04db6	916800000	5
166189	2026-05-15 05:49:00.760701+00	\\xb827ebfffe158993	916800000	5
166190	2026-05-15 05:49:01.786423+00	\\xb827ebfffef81e69	916800000	5
166191	2026-05-15 05:49:02.795615+00	\\xb827ebfffe78ffce	916800000	5
166192	2026-05-15 05:49:03.805837+00	\\xe45f01fffe10e12e	916800000	5
166193	2026-05-15 05:49:04.816191+00	\\xa840411b7dcc4150	916800000	5
166194	2026-05-15 05:49:05.828677+00	\\xb827ebfffea04db6	916800000	5
166195	2026-05-15 06:49:01.143233+00	\\xb827ebfffe158993	916800000	5
166196	2026-05-15 06:49:02.174579+00	\\xb827ebfffef81e69	916800000	5
166197	2026-05-15 06:49:03.19102+00	\\xb827ebfffe78ffce	916800000	5
166198	2026-05-15 06:49:04.201253+00	\\xe45f01fffe10e12e	916800000	5
166199	2026-05-15 06:49:05.214837+00	\\xa840411b7dcc4150	916800000	5
166200	2026-05-15 06:49:06.224965+00	\\xb827ebfffea04db6	916800000	5
166201	2026-05-15 07:49:01.720816+00	\\xb827ebfffe158993	916800000	5
166202	2026-05-15 07:49:02.747242+00	\\xb827ebfffef81e69	916800000	5
166203	2026-05-15 07:49:03.768642+00	\\xb827ebfffe78ffce	916800000	5
166204	2026-05-15 07:49:04.778918+00	\\xe45f01fffe10e12e	916800000	5
166205	2026-05-15 07:49:05.789685+00	\\xa840411b7dcc4150	916800000	5
166206	2026-05-15 07:49:06.799665+00	\\xb827ebfffea04db6	916800000	5
166207	2026-05-15 08:49:02.242965+00	\\xb827ebfffe158993	916800000	5
166208	2026-05-15 08:49:03.260763+00	\\xb827ebfffef81e69	916800000	5
166209	2026-05-15 08:49:04.279416+00	\\xb827ebfffe78ffce	916800000	5
166210	2026-05-15 08:49:05.289194+00	\\xe45f01fffe10e12e	916800000	5
166211	2026-05-15 08:49:06.301712+00	\\xa840411b7dcc4150	916800000	5
166212	2026-05-15 08:49:07.311952+00	\\xb827ebfffea04db6	916800000	5
166213	2026-05-15 09:49:02.896018+00	\\xb827ebfffe158993	916800000	5
166214	2026-05-15 09:49:03.91649+00	\\xb827ebfffef81e69	916800000	5
166215	2026-05-15 09:49:04.927604+00	\\xb827ebfffe78ffce	916800000	5
166216	2026-05-15 09:49:05.939069+00	\\xe45f01fffe10e12e	916800000	5
166217	2026-05-15 09:49:06.948175+00	\\xa840411b7dcc4150	916800000	5
166218	2026-05-15 09:49:07.959025+00	\\xb827ebfffea04db6	916800000	5
166219	2026-05-15 10:49:03.456306+00	\\xb827ebfffe158993	916800000	5
166220	2026-05-15 10:49:04.474581+00	\\xb827ebfffef81e69	916800000	5
166221	2026-05-15 10:49:05.487578+00	\\xb827ebfffe78ffce	916800000	5
166222	2026-05-15 10:49:06.496929+00	\\xe45f01fffe10e12e	916800000	5
166223	2026-05-15 10:49:07.506168+00	\\xa840411b7dcc4150	916800000	5
166224	2026-05-15 10:49:08.51554+00	\\xb827ebfffea04db6	916800000	5
166225	2026-05-15 11:49:03.929906+00	\\xb827ebfffe158993	916800000	5
166226	2026-05-15 11:49:04.947389+00	\\xb827ebfffef81e69	916800000	5
166227	2026-05-15 11:49:05.956782+00	\\xb827ebfffe78ffce	916800000	5
166228	2026-05-15 11:49:06.967721+00	\\xe45f01fffe10e12e	916800000	5
166229	2026-05-15 11:49:07.977729+00	\\xa840411b7dcc4150	916800000	5
166230	2026-05-15 11:49:08.989103+00	\\xb827ebfffea04db6	916800000	5
166231	2026-05-15 12:49:04.367301+00	\\xb827ebfffe158993	916800000	5
166232	2026-05-15 12:49:05.384849+00	\\xb827ebfffef81e69	916800000	5
166233	2026-05-15 12:49:06.40638+00	\\xb827ebfffe78ffce	916800000	5
166234	2026-05-15 12:49:07.418156+00	\\xe45f01fffe10e12e	916800000	5
166235	2026-05-15 12:49:08.431388+00	\\xa840411b7dcc4150	916800000	5
166236	2026-05-15 12:49:09.443428+00	\\xb827ebfffea04db6	916800000	5
166237	2026-05-15 13:49:04.854186+00	\\xb827ebfffe158993	916800000	5
166238	2026-05-15 13:49:05.876324+00	\\xb827ebfffef81e69	916800000	5
166239	2026-05-15 13:49:06.888103+00	\\xb827ebfffe78ffce	916800000	5
166240	2026-05-15 13:49:07.901319+00	\\xe45f01fffe10e12e	916800000	5
166241	2026-05-15 13:49:08.91151+00	\\xa840411b7dcc4150	916800000	5
166242	2026-05-15 13:49:09.921606+00	\\xb827ebfffea04db6	916800000	5
166243	2026-05-15 14:49:05.076861+00	\\xb827ebfffe158993	916800000	5
166244	2026-05-15 14:49:06.094181+00	\\xb827ebfffef81e69	916800000	5
166245	2026-05-15 14:49:07.124701+00	\\xb827ebfffe78ffce	916800000	5
166246	2026-05-15 14:49:08.136123+00	\\xe45f01fffe10e12e	916800000	5
166247	2026-05-15 14:49:09.145831+00	\\xa840411b7dcc4150	916800000	5
166248	2026-05-15 14:49:10.155735+00	\\xb827ebfffea04db6	916800000	5
166249	2026-05-15 15:49:05.553314+00	\\xb827ebfffe158993	916800000	5
166250	2026-05-15 15:49:06.571737+00	\\xb827ebfffef81e69	916800000	5
166251	2026-05-15 15:49:07.581046+00	\\xb827ebfffe78ffce	916800000	5
166252	2026-05-15 15:49:08.592044+00	\\xe45f01fffe10e12e	916800000	5
166253	2026-05-15 15:49:09.602102+00	\\xa840411b7dcc4150	916800000	5
166254	2026-05-15 15:49:10.611395+00	\\xb827ebfffea04db6	916800000	5
166255	2026-05-15 16:49:06.008425+00	\\xb827ebfffe158993	916800000	5
166256	2026-05-15 16:49:07.026228+00	\\xb827ebfffef81e69	916800000	5
166257	2026-05-15 16:49:08.036785+00	\\xb827ebfffe78ffce	916800000	5
166258	2026-05-15 16:49:09.047075+00	\\xe45f01fffe10e12e	916800000	5
166259	2026-05-15 16:49:10.057279+00	\\xa840411b7dcc4150	916800000	5
166260	2026-05-15 16:49:11.067458+00	\\xb827ebfffea04db6	916800000	5
166261	2026-05-15 17:49:06.533119+00	\\xb827ebfffe158993	916800000	5
166262	2026-05-15 17:49:07.549378+00	\\xb827ebfffef81e69	916800000	5
166263	2026-05-15 17:49:08.558553+00	\\xb827ebfffe78ffce	916800000	5
166264	2026-05-15 17:49:09.568836+00	\\xe45f01fffe10e12e	916800000	5
166265	2026-05-15 17:49:10.57907+00	\\xa840411b7dcc4150	916800000	5
166266	2026-05-15 17:49:11.588873+00	\\xb827ebfffea04db6	916800000	5
166267	2026-05-15 18:49:06.712921+00	\\xb827ebfffe158993	916800000	5
166268	2026-05-15 18:49:07.729238+00	\\xb827ebfffef81e69	916800000	5
166269	2026-05-15 18:49:08.738716+00	\\xb827ebfffe78ffce	916800000	5
166270	2026-05-15 18:49:09.749318+00	\\xe45f01fffe10e12e	916800000	5
166271	2026-05-15 18:49:10.770496+00	\\xa840411b7dcc4150	916800000	5
166272	2026-05-15 18:49:11.786018+00	\\xb827ebfffea04db6	916800000	5
166273	2026-05-15 19:49:07.164194+00	\\xb827ebfffe158993	916800000	5
166274	2026-05-15 19:49:08.187799+00	\\xb827ebfffef81e69	916800000	5
166275	2026-05-15 19:49:09.199561+00	\\xb827ebfffe78ffce	916800000	5
166276	2026-05-15 19:49:10.209958+00	\\xe45f01fffe10e12e	916800000	5
166277	2026-05-15 19:49:11.222221+00	\\xa840411b7dcc4150	916800000	5
166278	2026-05-15 19:49:12.231236+00	\\xb827ebfffea04db6	916800000	5
166279	2026-05-15 20:49:07.648943+00	\\xb827ebfffe158993	916800000	5
166280	2026-05-15 20:49:08.665486+00	\\xb827ebfffef81e69	916800000	5
166281	2026-05-15 20:49:09.674592+00	\\xb827ebfffe78ffce	916800000	5
166282	2026-05-15 20:49:10.684782+00	\\xe45f01fffe10e12e	916800000	5
166283	2026-05-15 20:49:11.694281+00	\\xa840411b7dcc4150	916800000	5
166284	2026-05-15 20:49:12.707842+00	\\xb827ebfffea04db6	916800000	5
166285	2026-05-15 21:49:08.061995+00	\\xb827ebfffe158993	916800000	5
166286	2026-05-15 21:49:09.081679+00	\\xb827ebfffef81e69	916800000	5
166287	2026-05-15 21:49:10.091463+00	\\xb827ebfffe78ffce	916800000	5
166288	2026-05-15 21:49:11.105583+00	\\xe45f01fffe10e12e	916800000	5
166289	2026-05-15 21:49:12.116928+00	\\xa840411b7dcc4150	916800000	5
166290	2026-05-15 21:49:13.126917+00	\\xb827ebfffea04db6	916800000	5
166291	2026-05-15 22:49:08.257898+00	\\xb827ebfffe158993	916800000	5
166292	2026-05-15 22:49:09.276919+00	\\xb827ebfffef81e69	916800000	5
166293	2026-05-15 22:49:10.285966+00	\\xb827ebfffe78ffce	916800000	5
166294	2026-05-15 22:49:11.296707+00	\\xe45f01fffe10e12e	916800000	5
166295	2026-05-15 22:49:12.31032+00	\\xa840411b7dcc4150	916800000	5
166296	2026-05-15 22:49:13.323833+00	\\xb827ebfffea04db6	916800000	5
166297	2026-05-15 23:49:08.406647+00	\\xb827ebfffe158993	916800000	5
166298	2026-05-15 23:49:09.437748+00	\\xb827ebfffef81e69	916800000	5
166299	2026-05-15 23:49:10.452947+00	\\xb827ebfffe78ffce	916800000	5
166300	2026-05-15 23:49:11.468151+00	\\xe45f01fffe10e12e	916800000	5
166301	2026-05-15 23:49:12.485602+00	\\xa840411b7dcc4150	916800000	5
166302	2026-05-15 23:49:13.506922+00	\\xb827ebfffea04db6	916800000	5
166303	2026-05-16 00:49:08.822987+00	\\xb827ebfffe158993	916800000	5
166304	2026-05-16 00:49:09.842714+00	\\xb827ebfffef81e69	916800000	5
166305	2026-05-16 00:49:10.861947+00	\\xb827ebfffe78ffce	916800000	5
166306	2026-05-16 00:49:11.892212+00	\\xe45f01fffe10e12e	916800000	5
166307	2026-05-16 00:49:12.910673+00	\\xa840411b7dcc4150	916800000	5
166308	2026-05-16 00:49:13.951587+00	\\xb827ebfffea04db6	916800000	5
166309	2026-05-16 01:49:09.385888+00	\\xb827ebfffe158993	916800000	5
166310	2026-05-16 01:49:10.40576+00	\\xb827ebfffef81e69	916800000	5
166311	2026-05-16 01:49:11.417692+00	\\xb827ebfffe78ffce	916800000	5
166312	2026-05-16 01:49:12.428033+00	\\xe45f01fffe10e12e	916800000	5
166313	2026-05-16 01:49:13.445299+00	\\xa840411b7dcc4150	916800000	5
166314	2026-05-16 01:49:14.454975+00	\\xb827ebfffea04db6	916800000	5
166315	2026-05-16 02:49:09.450813+00	\\xb827ebfffe158993	916800000	5
166316	2026-05-16 02:49:10.467414+00	\\xb827ebfffef81e69	916800000	5
166317	2026-05-16 02:49:11.47761+00	\\xb827ebfffe78ffce	916800000	5
166318	2026-05-16 02:49:12.491939+00	\\xe45f01fffe10e12e	916800000	5
166319	2026-05-16 02:49:13.504624+00	\\xa840411b7dcc4150	916800000	5
166320	2026-05-16 02:49:14.513886+00	\\xb827ebfffea04db6	916800000	5
166321	2026-05-16 03:49:09.562718+00	\\xb827ebfffe158993	916800000	5
166322	2026-05-16 03:49:10.578911+00	\\xb827ebfffef81e69	916800000	5
166323	2026-05-16 03:49:11.589619+00	\\xb827ebfffe78ffce	916800000	5
166324	2026-05-16 03:49:12.605851+00	\\xe45f01fffe10e12e	916800000	5
166325	2026-05-16 03:49:13.617667+00	\\xa840411b7dcc4150	916800000	5
166326	2026-05-16 03:49:14.629572+00	\\xb827ebfffea04db6	916800000	5
166327	2026-05-16 04:49:10.184628+00	\\xb827ebfffe158993	916800000	5
166328	2026-05-16 04:49:11.205126+00	\\xb827ebfffef81e69	916800000	5
166329	2026-05-16 04:49:12.216074+00	\\xb827ebfffe78ffce	916800000	5
166330	2026-05-16 04:49:13.227073+00	\\xe45f01fffe10e12e	916800000	5
166331	2026-05-16 04:49:14.239785+00	\\xa840411b7dcc4150	916800000	5
166332	2026-05-16 04:49:15.248915+00	\\xb827ebfffea04db6	916800000	5
166333	2026-05-16 05:49:11.076627+00	\\xb827ebfffe158993	916800000	5
166334	2026-05-16 05:49:12.097827+00	\\xb827ebfffef81e69	916800000	5
166335	2026-05-16 05:49:13.108438+00	\\xb827ebfffe78ffce	916800000	5
166336	2026-05-16 05:49:14.121827+00	\\xe45f01fffe10e12e	916800000	5
166337	2026-05-16 05:49:15.131749+00	\\xa840411b7dcc4150	916800000	5
166338	2026-05-16 05:49:16.142145+00	\\xb827ebfffea04db6	916800000	5
166339	2026-05-16 06:49:11.746915+00	\\xb827ebfffe158993	916800000	5
166340	2026-05-16 06:49:12.766209+00	\\xb827ebfffef81e69	916800000	5
166341	2026-05-16 06:49:13.782218+00	\\xb827ebfffe78ffce	916800000	5
166342	2026-05-16 06:49:14.792297+00	\\xe45f01fffe10e12e	916800000	5
166343	2026-05-16 06:49:15.804997+00	\\xa840411b7dcc4150	916800000	5
166344	2026-05-16 06:49:16.828146+00	\\xb827ebfffea04db6	916800000	5
166345	2026-05-16 07:49:12.039083+00	\\xb827ebfffe158993	916800000	5
166346	2026-05-16 07:49:13.066888+00	\\xb827ebfffef81e69	916800000	5
166347	2026-05-16 07:49:14.078679+00	\\xb827ebfffe78ffce	916800000	5
166348	2026-05-16 07:49:15.08806+00	\\xe45f01fffe10e12e	916800000	5
166349	2026-05-16 07:49:16.098799+00	\\xa840411b7dcc4150	916800000	5
166350	2026-05-16 07:49:17.109672+00	\\xb827ebfffea04db6	916800000	5
166351	2026-05-16 08:49:12.297605+00	\\xb827ebfffe158993	916800000	5
166352	2026-05-16 08:49:13.31758+00	\\xb827ebfffef81e69	916800000	5
166353	2026-05-16 08:49:14.327658+00	\\xb827ebfffe78ffce	916800000	5
166354	2026-05-16 08:49:15.337091+00	\\xe45f01fffe10e12e	916800000	5
166355	2026-05-16 08:49:16.346915+00	\\xa840411b7dcc4150	916800000	5
166356	2026-05-16 08:49:17.359507+00	\\xb827ebfffea04db6	916800000	5
166357	2026-05-16 09:49:12.323025+00	\\xb827ebfffe158993	916800000	5
166358	2026-05-16 09:49:13.346701+00	\\xb827ebfffef81e69	916800000	5
166359	2026-05-16 09:49:14.356579+00	\\xb827ebfffe78ffce	916800000	5
166360	2026-05-16 09:49:15.36692+00	\\xe45f01fffe10e12e	916800000	5
166361	2026-05-16 09:49:16.377396+00	\\xa840411b7dcc4150	916800000	5
166362	2026-05-16 09:49:17.387478+00	\\xb827ebfffea04db6	916800000	5
166363	2026-05-16 10:49:13.091774+00	\\xb827ebfffe158993	916800000	5
166364	2026-05-16 10:49:14.110416+00	\\xb827ebfffef81e69	916800000	5
166365	2026-05-16 10:49:15.121561+00	\\xb827ebfffe78ffce	916800000	5
166366	2026-05-16 10:49:16.13418+00	\\xe45f01fffe10e12e	916800000	5
166367	2026-05-16 10:49:17.143703+00	\\xa840411b7dcc4150	916800000	5
166368	2026-05-16 10:49:18.153625+00	\\xb827ebfffea04db6	916800000	5
166369	2026-05-16 11:49:13.755452+00	\\xb827ebfffe158993	916800000	5
166370	2026-05-16 11:49:14.77812+00	\\xb827ebfffef81e69	916800000	5
166371	2026-05-16 11:49:15.790713+00	\\xb827ebfffe78ffce	916800000	5
166372	2026-05-16 11:49:16.800909+00	\\xe45f01fffe10e12e	916800000	5
166373	2026-05-16 11:49:17.810972+00	\\xa840411b7dcc4150	916800000	5
166374	2026-05-16 11:49:18.820837+00	\\xb827ebfffea04db6	916800000	5
166375	2026-05-16 12:49:14.654589+00	\\xb827ebfffe158993	916800000	5
166376	2026-05-16 12:49:15.677343+00	\\xb827ebfffef81e69	916800000	5
166377	2026-05-16 12:49:16.68732+00	\\xb827ebfffe78ffce	916800000	5
166378	2026-05-16 12:49:17.697849+00	\\xe45f01fffe10e12e	916800000	5
166379	2026-05-16 12:49:18.707835+00	\\xa840411b7dcc4150	916800000	5
166380	2026-05-16 12:49:19.717906+00	\\xb827ebfffea04db6	916800000	5
166381	2026-05-16 13:49:14.944031+00	\\xb827ebfffe158993	916800000	5
166382	2026-05-16 13:49:15.961174+00	\\xb827ebfffef81e69	916800000	5
166383	2026-05-16 13:49:16.971304+00	\\xb827ebfffe78ffce	916800000	5
166384	2026-05-16 13:49:17.982965+00	\\xe45f01fffe10e12e	916800000	5
166385	2026-05-16 13:49:18.9925+00	\\xa840411b7dcc4150	916800000	5
166386	2026-05-16 13:49:20.002116+00	\\xb827ebfffea04db6	916800000	5
166387	2026-05-16 14:49:15.38685+00	\\xb827ebfffe158993	916800000	5
166388	2026-05-16 14:49:16.4078+00	\\xb827ebfffef81e69	916800000	5
166389	2026-05-16 14:49:17.418686+00	\\xb827ebfffe78ffce	916800000	5
166390	2026-05-16 14:49:18.429585+00	\\xe45f01fffe10e12e	916800000	5
166391	2026-05-16 14:49:19.443442+00	\\xa840411b7dcc4150	916800000	5
166392	2026-05-16 14:49:20.453698+00	\\xb827ebfffea04db6	916800000	5
166393	2026-05-16 15:49:16.350851+00	\\xb827ebfffe158993	916800000	5
166394	2026-05-16 15:49:17.375245+00	\\xb827ebfffef81e69	916800000	5
166395	2026-05-16 15:49:18.384935+00	\\xb827ebfffe78ffce	916800000	5
166396	2026-05-16 15:49:19.396588+00	\\xe45f01fffe10e12e	916800000	5
166397	2026-05-16 15:49:20.406491+00	\\xa840411b7dcc4150	916800000	5
166398	2026-05-16 15:49:21.416724+00	\\xb827ebfffea04db6	916800000	5
166399	2026-05-16 16:49:16.68479+00	\\xb827ebfffe158993	916800000	5
166400	2026-05-16 16:49:17.704002+00	\\xb827ebfffef81e69	916800000	5
166401	2026-05-16 16:49:18.715443+00	\\xb827ebfffe78ffce	916800000	5
166402	2026-05-16 16:49:19.725869+00	\\xe45f01fffe10e12e	916800000	5
166403	2026-05-16 16:49:20.739006+00	\\xa840411b7dcc4150	916800000	5
166404	2026-05-16 16:49:21.750741+00	\\xb827ebfffea04db6	916800000	5
166405	2026-05-16 17:49:16.853676+00	\\xb827ebfffe158993	916800000	5
166406	2026-05-16 17:49:17.870244+00	\\xb827ebfffef81e69	916800000	5
166407	2026-05-16 17:49:18.880883+00	\\xb827ebfffe78ffce	916800000	5
166408	2026-05-16 17:49:19.89041+00	\\xe45f01fffe10e12e	916800000	5
166409	2026-05-16 17:49:20.903855+00	\\xa840411b7dcc4150	916800000	5
166410	2026-05-16 17:49:21.9163+00	\\xb827ebfffea04db6	916800000	5
166411	2026-05-16 18:49:17.054853+00	\\xb827ebfffe158993	916800000	5
166412	2026-05-16 18:49:18.072292+00	\\xb827ebfffef81e69	916800000	5
166413	2026-05-16 18:49:19.08574+00	\\xb827ebfffe78ffce	916800000	5
166414	2026-05-16 18:49:20.095814+00	\\xe45f01fffe10e12e	916800000	5
166415	2026-05-16 18:49:21.109041+00	\\xa840411b7dcc4150	916800000	5
166416	2026-05-16 18:49:22.119019+00	\\xb827ebfffea04db6	916800000	5
166417	2026-05-16 19:49:17.140061+00	\\xb827ebfffe158993	916800000	5
166418	2026-05-16 19:49:18.158699+00	\\xb827ebfffef81e69	916800000	5
166419	2026-05-16 19:49:19.169872+00	\\xb827ebfffe78ffce	916800000	5
166420	2026-05-16 19:49:20.180305+00	\\xe45f01fffe10e12e	916800000	5
166421	2026-05-16 19:49:21.190603+00	\\xa840411b7dcc4150	916800000	5
166422	2026-05-16 19:49:22.200145+00	\\xb827ebfffea04db6	916800000	5
166423	2026-05-16 20:49:17.458911+00	\\xb827ebfffe158993	916800000	5
166424	2026-05-16 20:49:18.476605+00	\\xb827ebfffef81e69	916800000	5
166425	2026-05-16 20:49:19.486735+00	\\xb827ebfffe78ffce	916800000	5
166426	2026-05-16 20:49:20.497964+00	\\xe45f01fffe10e12e	916800000	5
166427	2026-05-16 20:49:21.510278+00	\\xa840411b7dcc4150	916800000	5
166428	2026-05-16 20:49:22.527856+00	\\xb827ebfffea04db6	916800000	5
166429	2026-05-16 21:49:17.594741+00	\\xb827ebfffe158993	916800000	5
166430	2026-05-16 21:49:18.655597+00	\\xb827ebfffef81e69	916800000	5
166431	2026-05-16 21:49:19.666499+00	\\xb827ebfffe78ffce	916800000	5
166432	2026-05-16 21:49:20.67721+00	\\xe45f01fffe10e12e	916800000	5
166433	2026-05-16 21:49:21.686695+00	\\xa840411b7dcc4150	916800000	5
166434	2026-05-16 21:49:22.69903+00	\\xb827ebfffea04db6	916800000	5
166435	2026-05-16 22:49:18.568548+00	\\xb827ebfffe158993	916800000	5
166436	2026-05-16 22:49:19.58636+00	\\xb827ebfffef81e69	916800000	5
166437	2026-05-16 22:49:20.5969+00	\\xb827ebfffe78ffce	916800000	5
166438	2026-05-16 22:49:21.610713+00	\\xe45f01fffe10e12e	916800000	5
166439	2026-05-16 22:49:22.623292+00	\\xa840411b7dcc4150	916800000	5
166440	2026-05-16 22:49:23.636552+00	\\xb827ebfffea04db6	916800000	5
166441	2026-05-16 23:49:19.006786+00	\\xb827ebfffe158993	916800000	5
166442	2026-05-16 23:49:20.026318+00	\\xb827ebfffef81e69	916800000	5
166443	2026-05-16 23:49:21.042355+00	\\xb827ebfffe78ffce	916800000	5
166444	2026-05-16 23:49:22.059019+00	\\xe45f01fffe10e12e	916800000	5
166445	2026-05-16 23:49:23.069843+00	\\xa840411b7dcc4150	916800000	5
166446	2026-05-16 23:49:24.079935+00	\\xb827ebfffea04db6	916800000	5
166447	2026-05-17 00:49:19.152702+00	\\xb827ebfffe158993	916800000	5
166448	2026-05-17 00:49:20.171275+00	\\xb827ebfffef81e69	916800000	5
166449	2026-05-17 00:49:21.182505+00	\\xb827ebfffe78ffce	916800000	5
166450	2026-05-17 00:49:22.193164+00	\\xe45f01fffe10e12e	916800000	5
166451	2026-05-17 00:49:23.221658+00	\\xa840411b7dcc4150	916800000	5
166452	2026-05-17 00:49:24.249889+00	\\xb827ebfffea04db6	916800000	5
166453	2026-05-17 01:49:19.936718+00	\\xb827ebfffe158993	916800000	5
166454	2026-05-17 01:49:20.961517+00	\\xb827ebfffef81e69	916800000	5
166455	2026-05-17 01:49:21.972765+00	\\xb827ebfffe78ffce	916800000	5
166456	2026-05-17 01:49:22.98248+00	\\xe45f01fffe10e12e	916800000	5
166457	2026-05-17 01:49:23.99384+00	\\xa840411b7dcc4150	916800000	5
166458	2026-05-17 01:49:25.003148+00	\\xb827ebfffea04db6	916800000	5
166459	2026-05-17 02:49:20.479902+00	\\xb827ebfffe158993	916800000	5
166460	2026-05-17 02:49:21.496724+00	\\xb827ebfffef81e69	916800000	5
166461	2026-05-17 02:49:22.51123+00	\\xb827ebfffe78ffce	916800000	5
166462	2026-05-17 02:49:23.521608+00	\\xe45f01fffe10e12e	916800000	5
166463	2026-05-17 02:49:24.535012+00	\\xa840411b7dcc4150	916800000	5
166464	2026-05-17 02:49:25.545903+00	\\xb827ebfffea04db6	916800000	5
166465	2026-05-17 03:49:20.937354+00	\\xb827ebfffe158993	916800000	5
166466	2026-05-17 03:49:21.96505+00	\\xb827ebfffef81e69	916800000	5
166467	2026-05-17 03:49:22.97934+00	\\xb827ebfffe78ffce	916800000	5
166468	2026-05-17 03:49:23.992592+00	\\xe45f01fffe10e12e	916800000	5
166469	2026-05-17 03:49:25.003516+00	\\xa840411b7dcc4150	916800000	5
166470	2026-05-17 03:49:26.014024+00	\\xb827ebfffea04db6	916800000	5
166471	2026-05-17 04:49:21.605967+00	\\xb827ebfffe158993	916800000	5
166472	2026-05-17 04:49:22.62861+00	\\xb827ebfffef81e69	916800000	5
166473	2026-05-17 04:49:23.639445+00	\\xb827ebfffe78ffce	916800000	5
166474	2026-05-17 04:49:24.650098+00	\\xe45f01fffe10e12e	916800000	5
166475	2026-05-17 04:49:25.660757+00	\\xa840411b7dcc4150	916800000	5
166476	2026-05-17 04:49:26.673466+00	\\xb827ebfffea04db6	916800000	5
166477	2026-05-17 05:49:21.80916+00	\\xb827ebfffe158993	916800000	5
166478	2026-05-17 05:49:22.826126+00	\\xb827ebfffef81e69	916800000	5
166479	2026-05-17 05:49:23.839564+00	\\xb827ebfffe78ffce	916800000	5
166480	2026-05-17 05:49:24.850119+00	\\xe45f01fffe10e12e	916800000	5
166481	2026-05-17 05:49:25.860018+00	\\xa840411b7dcc4150	916800000	5
166482	2026-05-17 05:49:26.869912+00	\\xb827ebfffea04db6	916800000	5
166483	2026-05-17 06:49:22.788058+00	\\xb827ebfffe158993	916800000	5
166484	2026-05-17 06:49:23.805054+00	\\xb827ebfffef81e69	916800000	5
166485	2026-05-17 06:49:24.815878+00	\\xb827ebfffe78ffce	916800000	5
166486	2026-05-17 06:49:25.826499+00	\\xe45f01fffe10e12e	916800000	5
166487	2026-05-17 06:49:26.837356+00	\\xa840411b7dcc4150	916800000	5
166488	2026-05-17 06:49:27.847373+00	\\xb827ebfffea04db6	916800000	5
166489	2026-05-17 07:49:23.079204+00	\\xb827ebfffe158993	916800000	5
166490	2026-05-17 07:49:24.099764+00	\\xb827ebfffef81e69	916800000	5
166491	2026-05-17 07:49:25.110864+00	\\xb827ebfffe78ffce	916800000	5
166492	2026-05-17 07:49:26.122125+00	\\xe45f01fffe10e12e	916800000	5
166493	2026-05-17 07:49:27.137467+00	\\xa840411b7dcc4150	916800000	5
166494	2026-05-17 07:49:28.147567+00	\\xb827ebfffea04db6	916800000	5
166495	2026-05-17 08:49:23.309947+00	\\xb827ebfffe158993	916800000	5
166496	2026-05-17 08:49:24.327597+00	\\xb827ebfffef81e69	916800000	5
166497	2026-05-17 08:49:25.338667+00	\\xb827ebfffe78ffce	916800000	5
166498	2026-05-17 08:49:26.349477+00	\\xe45f01fffe10e12e	916800000	5
166499	2026-05-17 08:49:27.362079+00	\\xa840411b7dcc4150	916800000	5
166500	2026-05-17 08:49:28.37469+00	\\xb827ebfffea04db6	916800000	5
166501	2026-05-17 09:49:23.749099+00	\\xb827ebfffe158993	916800000	5
166502	2026-05-17 09:49:24.770123+00	\\xb827ebfffef81e69	916800000	5
166503	2026-05-17 09:49:25.78079+00	\\xb827ebfffe78ffce	916800000	5
166504	2026-05-17 09:49:26.790768+00	\\xe45f01fffe10e12e	916800000	5
166505	2026-05-17 09:49:27.801068+00	\\xa840411b7dcc4150	916800000	5
166506	2026-05-17 09:49:28.810583+00	\\xb827ebfffea04db6	916800000	5
166507	2026-05-17 10:49:24.086794+00	\\xb827ebfffe158993	916800000	5
166508	2026-05-17 10:49:25.107678+00	\\xb827ebfffef81e69	916800000	5
166509	2026-05-17 10:49:26.117569+00	\\xb827ebfffe78ffce	916800000	5
166510	2026-05-17 10:49:27.127925+00	\\xe45f01fffe10e12e	916800000	5
166511	2026-05-17 10:49:28.138301+00	\\xa840411b7dcc4150	916800000	5
166512	2026-05-17 10:49:29.148672+00	\\xb827ebfffea04db6	916800000	5
166513	2026-05-17 11:49:24.632682+00	\\xb827ebfffe158993	916800000	5
166514	2026-05-17 11:49:25.651259+00	\\xb827ebfffef81e69	916800000	5
166515	2026-05-17 11:49:26.660782+00	\\xb827ebfffe78ffce	916800000	5
166516	2026-05-17 11:49:27.671341+00	\\xe45f01fffe10e12e	916800000	5
166517	2026-05-17 11:49:28.682165+00	\\xa840411b7dcc4150	916800000	5
166518	2026-05-17 11:49:29.694722+00	\\xb827ebfffea04db6	916800000	5
166519	2026-05-17 12:49:25.460772+00	\\xb827ebfffe158993	916800000	5
166520	2026-05-17 12:49:26.477789+00	\\xb827ebfffef81e69	916800000	5
166521	2026-05-17 12:49:27.488043+00	\\xb827ebfffe78ffce	916800000	5
166522	2026-05-17 12:49:28.498596+00	\\xe45f01fffe10e12e	916800000	5
166523	2026-05-17 12:49:29.509746+00	\\xa840411b7dcc4150	916800000	5
166524	2026-05-17 12:49:30.52235+00	\\xb827ebfffea04db6	916800000	5
166525	2026-05-17 13:49:25.919468+00	\\xb827ebfffe158993	916800000	5
166526	2026-05-17 13:49:26.936615+00	\\xb827ebfffef81e69	916800000	5
166527	2026-05-17 13:49:27.946343+00	\\xb827ebfffe78ffce	916800000	5
166528	2026-05-17 13:49:28.959754+00	\\xe45f01fffe10e12e	916800000	5
166529	2026-05-17 13:49:29.970664+00	\\xa840411b7dcc4150	916800000	5
166530	2026-05-17 13:49:30.980799+00	\\xb827ebfffea04db6	916800000	5
166531	2026-05-17 14:49:26.6681+00	\\xb827ebfffe158993	916800000	5
166532	2026-05-17 14:49:27.67898+00	\\xb827ebfffef81e69	916800000	5
166533	2026-05-17 14:49:28.688261+00	\\xb827ebfffe78ffce	916800000	5
166534	2026-05-17 14:49:29.698524+00	\\xe45f01fffe10e12e	916800000	5
166535	2026-05-17 14:49:30.709108+00	\\xa840411b7dcc4150	916800000	5
166536	2026-05-17 14:49:31.722967+00	\\xb827ebfffea04db6	916800000	5
166537	2026-05-17 15:49:26.85193+00	\\xb827ebfffe158993	916800000	5
166538	2026-05-17 15:49:27.87039+00	\\xb827ebfffef81e69	916800000	5
166539	2026-05-17 15:49:28.883706+00	\\xb827ebfffe78ffce	916800000	5
166540	2026-05-17 15:49:29.894915+00	\\xe45f01fffe10e12e	916800000	5
166541	2026-05-17 15:49:30.906301+00	\\xa840411b7dcc4150	916800000	5
166542	2026-05-17 15:49:31.917676+00	\\xb827ebfffea04db6	916800000	5
166543	2026-05-17 16:49:27.459962+00	\\xb827ebfffe158993	916800000	5
166544	2026-05-17 16:49:28.482522+00	\\xb827ebfffef81e69	916800000	5
166545	2026-05-17 16:49:29.49382+00	\\xb827ebfffe78ffce	916800000	5
166546	2026-05-17 16:49:30.50641+00	\\xe45f01fffe10e12e	916800000	5
166547	2026-05-17 16:49:31.520635+00	\\xa840411b7dcc4150	916800000	5
166548	2026-05-17 16:49:32.534447+00	\\xb827ebfffea04db6	916800000	5
166549	2026-05-17 17:49:28.235284+00	\\xb827ebfffe158993	916800000	5
166550	2026-05-17 17:49:29.253861+00	\\xb827ebfffef81e69	916800000	5
166551	2026-05-17 17:49:30.263298+00	\\xb827ebfffe78ffce	916800000	5
166552	2026-05-17 17:49:31.272823+00	\\xe45f01fffe10e12e	916800000	5
166553	2026-05-17 17:49:32.283694+00	\\xa840411b7dcc4150	916800000	5
166554	2026-05-17 17:49:33.297377+00	\\xb827ebfffea04db6	916800000	5
166555	2026-05-17 18:49:29.146803+00	\\xb827ebfffe158993	916800000	5
166556	2026-05-17 18:49:30.164981+00	\\xb827ebfffef81e69	916800000	5
166557	2026-05-17 18:49:31.17611+00	\\xb827ebfffe78ffce	916800000	5
166558	2026-05-17 18:49:32.18876+00	\\xe45f01fffe10e12e	916800000	5
166559	2026-05-17 18:49:33.204633+00	\\xa840411b7dcc4150	916800000	5
166560	2026-05-17 18:49:34.221932+00	\\xb827ebfffea04db6	916800000	5
166561	2026-05-17 19:49:30.151819+00	\\xb827ebfffe158993	916800000	5
166562	2026-05-17 19:49:31.172412+00	\\xb827ebfffef81e69	916800000	5
166563	2026-05-17 19:49:32.186817+00	\\xb827ebfffe78ffce	916800000	5
166564	2026-05-17 19:49:33.203384+00	\\xe45f01fffe10e12e	916800000	5
166565	2026-05-17 19:49:34.220965+00	\\xa840411b7dcc4150	916800000	5
166566	2026-05-17 19:49:35.230753+00	\\xb827ebfffea04db6	916800000	5
166567	2026-05-17 20:49:30.337896+00	\\xb827ebfffe158993	916800000	5
166568	2026-05-17 20:49:31.359783+00	\\xb827ebfffef81e69	916800000	5
166569	2026-05-17 20:49:32.374835+00	\\xb827ebfffe78ffce	916800000	5
166570	2026-05-17 20:49:33.390351+00	\\xe45f01fffe10e12e	916800000	5
166571	2026-05-17 20:49:34.402821+00	\\xa840411b7dcc4150	916800000	5
166572	2026-05-17 20:49:35.413547+00	\\xb827ebfffea04db6	916800000	5
166573	2026-05-17 21:49:30.848622+00	\\xb827ebfffe158993	916800000	5
166574	2026-05-17 21:49:31.873706+00	\\xb827ebfffef81e69	916800000	5
166575	2026-05-17 21:49:32.884228+00	\\xb827ebfffe78ffce	916800000	5
166576	2026-05-17 21:49:33.896471+00	\\xe45f01fffe10e12e	916800000	5
166577	2026-05-17 21:49:34.907881+00	\\xa840411b7dcc4150	916800000	5
166578	2026-05-17 21:49:35.918252+00	\\xb827ebfffea04db6	916800000	5
166579	2026-05-17 22:49:30.942357+00	\\xb827ebfffe158993	916800000	5
166580	2026-05-17 22:49:31.98082+00	\\xb827ebfffef81e69	916800000	5
166581	2026-05-17 22:49:32.990695+00	\\xb827ebfffe78ffce	916800000	5
166582	2026-05-17 22:49:34.001887+00	\\xe45f01fffe10e12e	916800000	5
166583	2026-05-17 22:49:35.013102+00	\\xa840411b7dcc4150	916800000	5
166584	2026-05-17 22:49:36.022569+00	\\xb827ebfffea04db6	916800000	5
166585	2026-05-17 23:49:31.212497+00	\\xb827ebfffe158993	916800000	5
166586	2026-05-17 23:49:32.228968+00	\\xb827ebfffef81e69	916800000	5
166587	2026-05-17 23:49:33.23961+00	\\xb827ebfffe78ffce	916800000	5
166588	2026-05-17 23:49:34.250296+00	\\xe45f01fffe10e12e	916800000	5
166589	2026-05-17 23:49:35.260554+00	\\xa840411b7dcc4150	916800000	5
166590	2026-05-17 23:49:36.270135+00	\\xb827ebfffea04db6	916800000	5
166591	2026-05-18 00:49:31.784822+00	\\xb827ebfffe158993	916800000	5
166592	2026-05-18 00:49:32.803397+00	\\xb827ebfffef81e69	916800000	5
166593	2026-05-18 00:49:33.815765+00	\\xb827ebfffe78ffce	916800000	5
166594	2026-05-18 00:49:34.82812+00	\\xe45f01fffe10e12e	916800000	5
166595	2026-05-18 00:49:35.838313+00	\\xa840411b7dcc4150	916800000	5
166596	2026-05-18 00:49:36.848771+00	\\xb827ebfffea04db6	916800000	5
166597	2026-05-18 01:49:32.083928+00	\\xb827ebfffe158993	916800000	5
166598	2026-05-18 01:49:33.102578+00	\\xb827ebfffef81e69	916800000	5
166599	2026-05-18 01:49:34.113681+00	\\xb827ebfffe78ffce	916800000	5
166600	2026-05-18 01:49:35.123635+00	\\xe45f01fffe10e12e	916800000	5
166601	2026-05-18 01:49:36.133705+00	\\xa840411b7dcc4150	916800000	5
166602	2026-05-18 01:49:37.143429+00	\\xb827ebfffea04db6	916800000	5
166603	2026-05-18 02:49:32.521394+00	\\xb827ebfffe158993	916800000	5
166604	2026-05-18 02:49:33.53922+00	\\xb827ebfffef81e69	916800000	5
166605	2026-05-18 02:49:34.549804+00	\\xb827ebfffe78ffce	916800000	5
166606	2026-05-18 02:49:35.559794+00	\\xe45f01fffe10e12e	916800000	5
166607	2026-05-18 02:49:36.569574+00	\\xa840411b7dcc4150	916800000	5
166608	2026-05-18 02:49:37.579374+00	\\xb827ebfffea04db6	916800000	5
166609	2026-05-18 03:49:33.111841+00	\\xb827ebfffe158993	916800000	5
166610	2026-05-18 03:49:34.131162+00	\\xb827ebfffef81e69	916800000	5
166611	2026-05-18 03:49:35.141003+00	\\xb827ebfffe78ffce	916800000	5
166612	2026-05-18 03:49:36.151691+00	\\xe45f01fffe10e12e	916800000	5
166613	2026-05-18 03:49:37.161727+00	\\xa840411b7dcc4150	916800000	5
166614	2026-05-18 03:49:38.17304+00	\\xb827ebfffea04db6	916800000	5
166615	2026-05-18 04:49:33.405609+00	\\xb827ebfffe158993	916800000	5
166616	2026-05-18 04:49:34.42471+00	\\xb827ebfffef81e69	916800000	5
166617	2026-05-18 04:49:35.434667+00	\\xb827ebfffe78ffce	916800000	5
166618	2026-05-18 04:49:36.445024+00	\\xe45f01fffe10e12e	916800000	5
166619	2026-05-18 04:49:37.45507+00	\\xa840411b7dcc4150	916800000	5
166620	2026-05-18 04:49:38.465282+00	\\xb827ebfffea04db6	916800000	5
166621	2026-05-18 05:49:33.572867+00	\\xb827ebfffe158993	916800000	5
166622	2026-05-18 05:49:34.590568+00	\\xb827ebfffef81e69	916800000	5
166623	2026-05-18 05:49:35.600161+00	\\xb827ebfffe78ffce	916800000	5
166624	2026-05-18 05:49:36.610294+00	\\xe45f01fffe10e12e	916800000	5
166625	2026-05-18 05:49:37.620187+00	\\xa840411b7dcc4150	916800000	5
166626	2026-05-18 05:49:38.631316+00	\\xb827ebfffea04db6	916800000	5
166627	2026-05-18 06:49:34.180974+00	\\xb827ebfffe158993	916800000	5
166628	2026-05-18 06:49:35.198329+00	\\xb827ebfffef81e69	916800000	5
166629	2026-05-18 06:49:36.209636+00	\\xb827ebfffe78ffce	916800000	5
166630	2026-05-18 06:49:37.221141+00	\\xe45f01fffe10e12e	916800000	5
166631	2026-05-18 06:49:38.240768+00	\\xa840411b7dcc4150	916800000	5
166632	2026-05-18 06:49:39.25744+00	\\xb827ebfffea04db6	916800000	5
166633	2026-05-18 07:49:35.101708+00	\\xb827ebfffe158993	916800000	5
166634	2026-05-18 07:49:36.121425+00	\\xb827ebfffef81e69	916800000	5
166635	2026-05-18 07:49:37.133197+00	\\xb827ebfffe78ffce	916800000	5
166636	2026-05-18 07:49:38.148403+00	\\xe45f01fffe10e12e	916800000	5
166637	2026-05-18 07:49:39.158877+00	\\xa840411b7dcc4150	916800000	5
166638	2026-05-18 07:49:40.168439+00	\\xb827ebfffea04db6	916800000	5
166639	2026-05-18 08:49:35.985152+00	\\xb827ebfffe158993	916800000	5
166640	2026-05-18 08:49:37.017004+00	\\xb827ebfffef81e69	916800000	5
166641	2026-05-18 08:49:38.03167+00	\\xb827ebfffe78ffce	916800000	5
166642	2026-05-18 08:49:39.0426+00	\\xe45f01fffe10e12e	916800000	5
166643	2026-05-18 08:49:40.055346+00	\\xa840411b7dcc4150	916800000	5
166644	2026-05-18 08:49:41.065625+00	\\xb827ebfffea04db6	916800000	5
166645	2026-05-18 09:49:36.834065+00	\\xb827ebfffe158993	916800000	5
166646	2026-05-18 09:49:37.856177+00	\\xb827ebfffef81e69	916800000	5
166647	2026-05-18 09:49:38.866632+00	\\xb827ebfffe78ffce	916800000	5
166648	2026-05-18 09:49:39.879235+00	\\xe45f01fffe10e12e	916800000	5
166649	2026-05-18 09:49:40.889349+00	\\xa840411b7dcc4150	916800000	5
166650	2026-05-18 09:49:41.899391+00	\\xb827ebfffea04db6	916800000	5
166651	2026-05-18 10:49:37.791639+00	\\xb827ebfffe158993	916800000	5
166652	2026-05-18 10:49:38.844622+00	\\xb827ebfffef81e69	916800000	5
166653	2026-05-18 10:49:39.870348+00	\\xb827ebfffe78ffce	916800000	5
166654	2026-05-18 10:49:40.880608+00	\\xe45f01fffe10e12e	916800000	5
166655	2026-05-18 10:49:41.89116+00	\\xa840411b7dcc4150	916800000	5
166656	2026-05-18 10:49:42.900956+00	\\xb827ebfffea04db6	916800000	5
166657	2026-05-18 11:49:37.966789+00	\\xb827ebfffe158993	916800000	5
166658	2026-05-18 11:49:38.988343+00	\\xb827ebfffef81e69	916800000	5
166659	2026-05-18 11:49:40.008595+00	\\xb827ebfffe78ffce	916800000	5
166660	2026-05-18 11:49:41.021741+00	\\xe45f01fffe10e12e	916800000	5
166661	2026-05-18 11:49:42.031855+00	\\xa840411b7dcc4150	916800000	5
166662	2026-05-18 11:49:43.042148+00	\\xb827ebfffea04db6	916800000	5
166663	2026-05-18 12:49:38.851208+00	\\xb827ebfffe158993	916800000	5
166664	2026-05-18 12:49:39.873258+00	\\xb827ebfffef81e69	916800000	5
166665	2026-05-18 12:49:40.884236+00	\\xb827ebfffe78ffce	916800000	5
166666	2026-05-18 12:49:41.896156+00	\\xe45f01fffe10e12e	916800000	5
166667	2026-05-18 12:49:42.907889+00	\\xa840411b7dcc4150	916800000	5
166668	2026-05-18 12:49:43.920549+00	\\xb827ebfffea04db6	916800000	5
166669	2026-05-18 13:49:39.021118+00	\\xb827ebfffe158993	916800000	5
166670	2026-05-18 13:49:40.044686+00	\\xb827ebfffef81e69	916800000	5
166671	2026-05-18 13:49:41.054637+00	\\xb827ebfffe78ffce	916800000	5
166672	2026-05-18 13:49:42.064817+00	\\xe45f01fffe10e12e	916800000	5
166673	2026-05-18 13:49:43.074496+00	\\xa840411b7dcc4150	916800000	5
166674	2026-05-18 13:49:44.084567+00	\\xb827ebfffea04db6	916800000	5
166675	2026-05-18 14:49:39.394133+00	\\xb827ebfffe158993	916800000	5
166676	2026-05-18 14:49:40.426964+00	\\xb827ebfffef81e69	916800000	5
166677	2026-05-18 14:49:41.43766+00	\\xb827ebfffe78ffce	916800000	5
166678	2026-05-18 14:49:42.447867+00	\\xe45f01fffe10e12e	916800000	5
166679	2026-05-18 14:49:43.458155+00	\\xa840411b7dcc4150	916800000	5
166680	2026-05-18 14:49:44.477169+00	\\xb827ebfffea04db6	916800000	5
166681	2026-05-18 15:49:39.617843+00	\\xb827ebfffe158993	916800000	5
166682	2026-05-18 15:49:40.654247+00	\\xb827ebfffef81e69	916800000	5
166683	2026-05-18 15:49:41.667187+00	\\xb827ebfffe78ffce	916800000	5
166684	2026-05-18 15:49:42.677884+00	\\xe45f01fffe10e12e	916800000	5
166685	2026-05-18 15:49:43.689472+00	\\xa840411b7dcc4150	916800000	5
166686	2026-05-18 15:49:44.699114+00	\\xb827ebfffea04db6	916800000	5
166687	2026-05-18 16:49:39.787209+00	\\xb827ebfffe158993	916800000	5
166688	2026-05-18 16:49:40.807115+00	\\xb827ebfffef81e69	916800000	5
166689	2026-05-18 16:49:41.818958+00	\\xb827ebfffe78ffce	916800000	5
166690	2026-05-18 16:49:42.829353+00	\\xe45f01fffe10e12e	916800000	5
166691	2026-05-18 16:49:43.844978+00	\\xa840411b7dcc4150	916800000	5
166692	2026-05-18 16:49:44.854628+00	\\xb827ebfffea04db6	916800000	5
166693	2026-05-18 17:49:39.995073+00	\\xb827ebfffe158993	916800000	5
166694	2026-05-18 17:49:41.01498+00	\\xb827ebfffef81e69	916800000	5
166695	2026-05-18 17:49:42.028624+00	\\xb827ebfffe78ffce	916800000	5
166696	2026-05-18 17:49:43.038567+00	\\xe45f01fffe10e12e	916800000	5
166697	2026-05-18 17:49:44.049702+00	\\xa840411b7dcc4150	916800000	5
166698	2026-05-18 17:49:45.062565+00	\\xb827ebfffea04db6	916800000	5
166699	2026-05-18 18:49:40.513962+00	\\xb827ebfffe158993	916800000	5
166700	2026-05-18 18:49:41.532084+00	\\xb827ebfffef81e69	916800000	5
166701	2026-05-18 18:49:42.541735+00	\\xb827ebfffe78ffce	916800000	5
166702	2026-05-18 18:49:43.551923+00	\\xe45f01fffe10e12e	916800000	5
166703	2026-05-18 18:49:44.561701+00	\\xa840411b7dcc4150	916800000	5
166704	2026-05-18 18:49:45.570661+00	\\xb827ebfffea04db6	916800000	5
166705	2026-05-18 19:49:41.18013+00	\\xb827ebfffe158993	916800000	5
166706	2026-05-18 19:49:42.197062+00	\\xb827ebfffef81e69	916800000	5
166707	2026-05-18 19:49:43.207189+00	\\xb827ebfffe78ffce	916800000	5
166708	2026-05-18 19:49:44.218359+00	\\xe45f01fffe10e12e	916800000	5
166709	2026-05-18 19:49:45.227848+00	\\xa840411b7dcc4150	916800000	5
166710	2026-05-18 19:49:46.237195+00	\\xb827ebfffea04db6	916800000	5
166711	2026-05-18 20:49:41.340655+00	\\xb827ebfffe158993	916800000	5
166712	2026-05-18 20:49:42.358182+00	\\xb827ebfffef81e69	916800000	5
166713	2026-05-18 20:49:43.367898+00	\\xb827ebfffe78ffce	916800000	5
166714	2026-05-18 20:49:44.378228+00	\\xe45f01fffe10e12e	916800000	5
166715	2026-05-18 20:49:45.388019+00	\\xa840411b7dcc4150	916800000	5
166716	2026-05-18 20:49:46.407031+00	\\xb827ebfffea04db6	916800000	5
\.


--
-- TOC entry 3768 (class 0 OID 16902)
-- Dependencies: 226
-- Data for Name: gateway_ping_rx; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public.gateway_ping_rx (id, created_at, ping_id, gateway_mac, received_at, rssi, lora_snr, location, altitude) FROM stdin;
\.


--
-- TOC entry 3775 (class 0 OID 17146)
-- Dependencies: 233
-- Data for Name: gateway_profile; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public.gateway_profile (gateway_profile_id, network_server_id, created_at, updated_at, name, stats_interval) FROM stdin;
2064912e-be4a-4dd2-9b7e-702ccff3dcb4	1	2026-05-01 19:41:01.785339+00	2026-05-01 19:41:01.785339+00	ChirpStack-v3_GP_AU915_1	30000000000
544d2b2b-153c-4022-96c1-5f5aa8361361	1	2026-05-01 19:40:41.696241+00	2026-05-16 14:20:05.471954+00	ChirpStack-v3_GP_AU915_0	30000000000
\.


--
-- TOC entry 3764 (class 0 OID 16864)
-- Dependencies: 222
-- Data for Name: integration; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public.integration (id, created_at, updated_at, application_id, kind, settings) FROM stdin;
\.


--
-- TOC entry 3776 (class 0 OID 17196)
-- Dependencies: 234
-- Data for Name: multicast_group; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public.multicast_group (id, created_at, updated_at, name, mc_app_s_key, application_id) FROM stdin;
\.


--
-- TOC entry 3770 (class 0 OID 16942)
-- Dependencies: 228
-- Data for Name: network_server; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public.network_server (id, created_at, updated_at, name, server, ca_cert, tls_cert, tls_key, routing_profile_ca_cert, routing_profile_tls_cert, routing_profile_tls_key, gateway_discovery_enabled, gateway_discovery_interval, gateway_discovery_tx_frequency, gateway_discovery_dr) FROM stdin;
1	2026-05-01 19:39:52.968163+00	2026-05-16 14:20:10.31759+00	ChirpStack-v3_NS	chirpstack-v3-network-server-service.chirpstack-v3.svc.cluster.local:8000							t	24	916800000	5
\.


--
-- TOC entry 3759 (class 0 OID 16802)
-- Dependencies: 217
-- Data for Name: organization; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public.organization (id, created_at, updated_at, name, display_name, can_have_gateways, max_device_count, max_gateway_count) FROM stdin;
1	2026-05-01 15:01:48.314804+00	2026-05-01 15:01:48.314804+00	chirpstack	ChirpStack	t	0	0
\.


--
-- TOC entry 3761 (class 0 OID 16811)
-- Dependencies: 219
-- Data for Name: organization_user; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public.organization_user (id, created_at, updated_at, user_id, organization_id, is_admin, is_device_admin, is_gateway_admin) FROM stdin;
1	2026-05-01 15:01:48.314804+00	2026-05-01 15:01:48.314804+00	1	1	t	f	f
\.


--
-- TOC entry 3753 (class 0 OID 16595)
-- Dependencies: 211
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public.schema_migrations (version, dirty) FROM stdin;
60	f
\.


--
-- TOC entry 3771 (class 0 OID 16950)
-- Dependencies: 229
-- Data for Name: service_profile; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public.service_profile (service_profile_id, organization_id, network_server_id, created_at, updated_at, name) FROM stdin;
3dd33931-1cf7-4a56-8479-e88afa94a9e5	1	1	2026-05-01 19:42:55.94285+00	2026-05-16 14:20:33.136597+00	ChirpStack-v3_SP
\.


--
-- TOC entry 3757 (class 0 OID 16768)
-- Dependencies: 215
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: chirpstack_as
--

COPY public."user" (id, created_at, updated_at, email, password_hash, session_ttl, is_active, is_admin, email_old, note, external_id, email_verified) FROM stdin;
1	2026-05-01 15:01:48.160498+00	2026-05-01 19:50:32.450058+00	adail101@hotmail.com	PBKDF2$sha512$100000$9hv3NKPL1fw0rCnrFfk68g==$wak8VilUUZQraZNBm7vf6gqMpCJcRDnwdAkpWhqxAwMdKHe1QVDxJmkVxKAPBgkpem1V6YLoUO01z54dZ9CwKg==	0	t	t		AdailSilva-IoT	\N	f
\.


--
-- TOC entry 3797 (class 0 OID 0)
-- Dependencies: 212
-- Name: application_id_seq; Type: SEQUENCE SET; Schema: public; Owner: chirpstack_as
--

SELECT pg_catalog.setval('public.application_id_seq', 1, true);


--
-- TOC entry 3798 (class 0 OID 0)
-- Dependencies: 223
-- Name: gateway_ping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: chirpstack_as
--

SELECT pg_catalog.setval('public.gateway_ping_id_seq', 166716, true);


--
-- TOC entry 3799 (class 0 OID 0)
-- Dependencies: 225
-- Name: gateway_ping_rx_id_seq; Type: SEQUENCE SET; Schema: public; Owner: chirpstack_as
--

SELECT pg_catalog.setval('public.gateway_ping_rx_id_seq', 1, false);


--
-- TOC entry 3800 (class 0 OID 0)
-- Dependencies: 221
-- Name: integration_id_seq; Type: SEQUENCE SET; Schema: public; Owner: chirpstack_as
--

SELECT pg_catalog.setval('public.integration_id_seq', 1, false);


--
-- TOC entry 3801 (class 0 OID 0)
-- Dependencies: 227
-- Name: network_server_id_seq; Type: SEQUENCE SET; Schema: public; Owner: chirpstack_as
--

SELECT pg_catalog.setval('public.network_server_id_seq', 1, true);


--
-- TOC entry 3802 (class 0 OID 0)
-- Dependencies: 216
-- Name: organization_id_seq; Type: SEQUENCE SET; Schema: public; Owner: chirpstack_as
--

SELECT pg_catalog.setval('public.organization_id_seq', 1, true);


--
-- TOC entry 3803 (class 0 OID 0)
-- Dependencies: 218
-- Name: organization_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: chirpstack_as
--

SELECT pg_catalog.setval('public.organization_user_id_seq', 1, true);


--
-- TOC entry 3804 (class 0 OID 0)
-- Dependencies: 214
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: chirpstack_as
--

SELECT pg_catalog.setval('public.user_id_seq', 1, true);


--
-- TOC entry 3585 (class 2606 OID 17421)
-- Name: api_key api_key_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.api_key
    ADD CONSTRAINT api_key_pkey PRIMARY KEY (id);


--
-- TOC entry 3504 (class 2606 OID 16848)
-- Name: application application_name_organization_id_key; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.application
    ADD CONSTRAINT application_name_organization_id_key UNIQUE (name, organization_id);


--
-- TOC entry 3506 (class 2606 OID 16721)
-- Name: application application_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.application
    ADD CONSTRAINT application_pkey PRIMARY KEY (id);


--
-- TOC entry 3583 (class 2606 OID 17386)
-- Name: code_migration code_migration_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.code_migration
    ADD CONSTRAINT code_migration_pkey PRIMARY KEY (id);


--
-- TOC entry 3572 (class 2606 OID 17017)
-- Name: device_keys device_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.device_keys
    ADD CONSTRAINT device_keys_pkey PRIMARY KEY (dev_eui);


--
-- TOC entry 3581 (class 2606 OID 17216)
-- Name: device_multicast_group device_multicast_group_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.device_multicast_group
    ADD CONSTRAINT device_multicast_group_pkey PRIMARY KEY (multicast_group_id, dev_eui);


--
-- TOC entry 3563 (class 2606 OID 16994)
-- Name: device device_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_pkey PRIMARY KEY (dev_eui);


--
-- TOC entry 3558 (class 2606 OID 16973)
-- Name: device_profile device_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.device_profile
    ADD CONSTRAINT device_profile_pkey PRIMARY KEY (device_profile_id);


--
-- TOC entry 3525 (class 2606 OID 16839)
-- Name: gateway gateway_name_organization_id_key; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_name_organization_id_key UNIQUE (name, organization_id);


--
-- TOC entry 3545 (class 2606 OID 16893)
-- Name: gateway_ping gateway_ping_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.gateway_ping
    ADD CONSTRAINT gateway_ping_pkey PRIMARY KEY (id);


--
-- TOC entry 3548 (class 2606 OID 16909)
-- Name: gateway_ping_rx gateway_ping_rx_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.gateway_ping_rx
    ADD CONSTRAINT gateway_ping_rx_pkey PRIMARY KEY (id);


--
-- TOC entry 3527 (class 2606 OID 16837)
-- Name: gateway gateway_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_pkey PRIMARY KEY (mac);


--
-- TOC entry 3574 (class 2606 OID 17150)
-- Name: gateway_profile gateway_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.gateway_profile
    ADD CONSTRAINT gateway_profile_pkey PRIMARY KEY (gateway_profile_id);


--
-- TOC entry 3541 (class 2606 OID 16873)
-- Name: integration integration_kind_application_id; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.integration
    ADD CONSTRAINT integration_kind_application_id UNIQUE (kind, application_id);


--
-- TOC entry 3543 (class 2606 OID 16871)
-- Name: integration integration_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.integration
    ADD CONSTRAINT integration_pkey PRIMARY KEY (id);


--
-- TOC entry 3579 (class 2606 OID 17202)
-- Name: multicast_group multicast_group_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.multicast_group
    ADD CONSTRAINT multicast_group_pkey PRIMARY KEY (id);


--
-- TOC entry 3552 (class 2606 OID 16947)
-- Name: network_server network_server_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.network_server
    ADD CONSTRAINT network_server_pkey PRIMARY KEY (id);


--
-- TOC entry 3517 (class 2606 OID 16807)
-- Name: organization organization_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (id);


--
-- TOC entry 3521 (class 2606 OID 16816)
-- Name: organization_user organization_user_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.organization_user
    ADD CONSTRAINT organization_user_pkey PRIMARY KEY (id);


--
-- TOC entry 3523 (class 2606 OID 16818)
-- Name: organization_user organization_user_user_id_organization_id_key; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.organization_user
    ADD CONSTRAINT organization_user_user_id_organization_id_key UNIQUE (user_id, organization_id);


--
-- TOC entry 3502 (class 2606 OID 16599)
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- TOC entry 3556 (class 2606 OID 16954)
-- Name: service_profile service_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.service_profile
    ADD CONSTRAINT service_profile_pkey PRIMARY KEY (service_profile_id);


--
-- TOC entry 3513 (class 2606 OID 16773)
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- TOC entry 3586 (class 1259 OID 17433)
-- Name: idx_api_key_application_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_api_key_application_id ON public.api_key USING btree (application_id);


--
-- TOC entry 3587 (class 1259 OID 17432)
-- Name: idx_api_key_organization_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_api_key_organization_id ON public.api_key USING btree (organization_id);


--
-- TOC entry 3507 (class 1259 OID 17135)
-- Name: idx_application_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_application_name_trgm ON public.application USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3508 (class 1259 OID 16854)
-- Name: idx_application_organization_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_application_organization_id ON public.application USING btree (organization_id);


--
-- TOC entry 3509 (class 1259 OID 17065)
-- Name: idx_application_service_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_application_service_profile_id ON public.application USING btree (service_profile_id);


--
-- TOC entry 3564 (class 1259 OID 17007)
-- Name: idx_device_application_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_device_application_id ON public.device USING btree (application_id);


--
-- TOC entry 3565 (class 1259 OID 17489)
-- Name: idx_device_dev_addr_trgm; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_device_dev_addr_trgm ON public.device USING gin (encode(dev_addr, 'hex'::text) public.gin_trgm_ops);


--
-- TOC entry 3566 (class 1259 OID 17138)
-- Name: idx_device_dev_eui_trgm; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_device_dev_eui_trgm ON public.device USING gin (encode(dev_eui, 'hex'::text) public.gin_trgm_ops);


--
-- TOC entry 3567 (class 1259 OID 17008)
-- Name: idx_device_device_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_device_device_profile_id ON public.device USING btree (device_profile_id);


--
-- TOC entry 3568 (class 1259 OID 17182)
-- Name: idx_device_name_application_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE UNIQUE INDEX idx_device_name_application_id ON public.device USING btree (name, application_id);


--
-- TOC entry 3569 (class 1259 OID 17139)
-- Name: idx_device_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_device_name_trgm ON public.device USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3559 (class 1259 OID 16984)
-- Name: idx_device_profile_network_server_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_device_profile_network_server_id ON public.device_profile USING btree (network_server_id);


--
-- TOC entry 3560 (class 1259 OID 16985)
-- Name: idx_device_profile_organization_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_device_profile_organization_id ON public.device_profile USING btree (organization_id);


--
-- TOC entry 3561 (class 1259 OID 17411)
-- Name: idx_device_profile_tags; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_device_profile_tags ON public.device_profile USING gin (tags);


--
-- TOC entry 3570 (class 1259 OID 17401)
-- Name: idx_device_tags; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_device_tags ON public.device USING gin (tags);


--
-- TOC entry 3528 (class 1259 OID 17164)
-- Name: idx_gateway_gateway_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_gateway_gateway_profile_id ON public.gateway USING btree (gateway_profile_id);


--
-- TOC entry 3529 (class 1259 OID 16930)
-- Name: idx_gateway_last_ping_sent_at; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_gateway_last_ping_sent_at ON public.gateway USING btree (last_ping_sent_at);


--
-- TOC entry 3530 (class 1259 OID 17136)
-- Name: idx_gateway_mac_trgm; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_gateway_mac_trgm ON public.gateway USING gin (encode(mac, 'hex'::text) public.gin_trgm_ops);


--
-- TOC entry 3531 (class 1259 OID 17183)
-- Name: idx_gateway_name_organization_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE UNIQUE INDEX idx_gateway_name_organization_id ON public.gateway USING btree (name, organization_id);


--
-- TOC entry 3532 (class 1259 OID 17137)
-- Name: idx_gateway_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_gateway_name_trgm ON public.gateway USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3533 (class 1259 OID 17071)
-- Name: idx_gateway_network_server_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_gateway_network_server_id ON public.gateway USING btree (network_server_id);


--
-- TOC entry 3534 (class 1259 OID 16845)
-- Name: idx_gateway_organization_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_gateway_organization_id ON public.gateway USING btree (organization_id);


--
-- TOC entry 3535 (class 1259 OID 16929)
-- Name: idx_gateway_ping; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_gateway_ping ON public.gateway USING btree (ping);


--
-- TOC entry 3546 (class 1259 OID 16900)
-- Name: idx_gateway_ping_gateway_mac; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_gateway_ping_gateway_mac ON public.gateway_ping USING btree (gateway_mac);


--
-- TOC entry 3549 (class 1259 OID 16922)
-- Name: idx_gateway_ping_rx_gateway_mac; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_gateway_ping_rx_gateway_mac ON public.gateway_ping_rx USING btree (gateway_mac);


--
-- TOC entry 3550 (class 1259 OID 16921)
-- Name: idx_gateway_ping_rx_ping_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_gateway_ping_rx_ping_id ON public.gateway_ping_rx USING btree (ping_id);


--
-- TOC entry 3575 (class 1259 OID 17156)
-- Name: idx_gateway_profile_network_server_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_gateway_profile_network_server_id ON public.gateway_profile USING btree (network_server_id);


--
-- TOC entry 3536 (class 1259 OID 17474)
-- Name: idx_gateway_service_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_gateway_service_profile_id ON public.gateway USING btree (service_profile_id);


--
-- TOC entry 3537 (class 1259 OID 17406)
-- Name: idx_gateway_tags; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_gateway_tags ON public.gateway USING gin (tags);


--
-- TOC entry 3538 (class 1259 OID 16880)
-- Name: idx_integration_application_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_integration_application_id ON public.integration USING btree (application_id);


--
-- TOC entry 3539 (class 1259 OID 16879)
-- Name: idx_integration_kind; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_integration_kind ON public.integration USING btree (kind);


--
-- TOC entry 3576 (class 1259 OID 17484)
-- Name: idx_multicast_group_application_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_multicast_group_application_id ON public.multicast_group USING btree (application_id);


--
-- TOC entry 3577 (class 1259 OID 17208)
-- Name: idx_multicast_group_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_multicast_group_name_trgm ON public.multicast_group USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3514 (class 1259 OID 16808)
-- Name: idx_organization_name; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE UNIQUE INDEX idx_organization_name ON public.organization USING btree (name);


--
-- TOC entry 3515 (class 1259 OID 17140)
-- Name: idx_organization_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_organization_name_trgm ON public.organization USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3518 (class 1259 OID 16830)
-- Name: idx_organization_user_organization_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_organization_user_organization_id ON public.organization_user USING btree (organization_id);


--
-- TOC entry 3519 (class 1259 OID 16829)
-- Name: idx_organization_user_user_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_organization_user_user_id ON public.organization_user USING btree (user_id);


--
-- TOC entry 3553 (class 1259 OID 16966)
-- Name: idx_service_profile_network_server_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_service_profile_network_server_id ON public.service_profile USING btree (network_server_id);


--
-- TOC entry 3554 (class 1259 OID 16965)
-- Name: idx_service_profile_organization_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE INDEX idx_service_profile_organization_id ON public.service_profile USING btree (organization_id);


--
-- TOC entry 3510 (class 1259 OID 17439)
-- Name: idx_user_email; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE UNIQUE INDEX idx_user_email ON public."user" USING btree (email);


--
-- TOC entry 3511 (class 1259 OID 17440)
-- Name: idx_user_external_id; Type: INDEX; Schema: public; Owner: chirpstack_as
--

CREATE UNIQUE INDEX idx_user_external_id ON public."user" USING btree (external_id);


--
-- TOC entry 3612 (class 2606 OID 17427)
-- Name: api_key api_key_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.api_key
    ADD CONSTRAINT api_key_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.application(id) ON DELETE CASCADE;


--
-- TOC entry 3613 (class 2606 OID 17422)
-- Name: api_key api_key_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.api_key
    ADD CONSTRAINT api_key_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- TOC entry 3588 (class 2606 OID 16849)
-- Name: application application_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.application
    ADD CONSTRAINT application_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- TOC entry 3589 (class 2606 OID 17060)
-- Name: application application_service_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.application
    ADD CONSTRAINT application_service_profile_id_fkey FOREIGN KEY (service_profile_id) REFERENCES public.service_profile(service_profile_id);


--
-- TOC entry 3605 (class 2606 OID 16995)
-- Name: device device_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.application(id);


--
-- TOC entry 3606 (class 2606 OID 17000)
-- Name: device device_device_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_device_profile_id_fkey FOREIGN KEY (device_profile_id) REFERENCES public.device_profile(device_profile_id);


--
-- TOC entry 3607 (class 2606 OID 17018)
-- Name: device_keys device_keys_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.device_keys
    ADD CONSTRAINT device_keys_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3610 (class 2606 OID 17217)
-- Name: device_multicast_group device_multicast_group_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.device_multicast_group
    ADD CONSTRAINT device_multicast_group_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3611 (class 2606 OID 17222)
-- Name: device_multicast_group device_multicast_group_multicast_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.device_multicast_group
    ADD CONSTRAINT device_multicast_group_multicast_group_id_fkey FOREIGN KEY (multicast_group_id) REFERENCES public.multicast_group(id) ON DELETE CASCADE;


--
-- TOC entry 3603 (class 2606 OID 16974)
-- Name: device_profile device_profile_network_server_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.device_profile
    ADD CONSTRAINT device_profile_network_server_id_fkey FOREIGN KEY (network_server_id) REFERENCES public.network_server(id);


--
-- TOC entry 3604 (class 2606 OID 16979)
-- Name: device_profile device_profile_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.device_profile
    ADD CONSTRAINT device_profile_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id);


--
-- TOC entry 3592 (class 2606 OID 17159)
-- Name: gateway gateway_gateway_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_gateway_profile_id_fkey FOREIGN KEY (gateway_profile_id) REFERENCES public.gateway_profile(gateway_profile_id);


--
-- TOC entry 3593 (class 2606 OID 16924)
-- Name: gateway gateway_last_ping_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_last_ping_id_fkey FOREIGN KEY (last_ping_id) REFERENCES public.gateway_ping(id) ON DELETE SET NULL;


--
-- TOC entry 3594 (class 2606 OID 17066)
-- Name: gateway gateway_network_server_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_network_server_id_fkey FOREIGN KEY (network_server_id) REFERENCES public.network_server(id);


--
-- TOC entry 3595 (class 2606 OID 16840)
-- Name: gateway gateway_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- TOC entry 3598 (class 2606 OID 16894)
-- Name: gateway_ping gateway_ping_gateway_mac_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.gateway_ping
    ADD CONSTRAINT gateway_ping_gateway_mac_fkey FOREIGN KEY (gateway_mac) REFERENCES public.gateway(mac) ON DELETE CASCADE;


--
-- TOC entry 3599 (class 2606 OID 16915)
-- Name: gateway_ping_rx gateway_ping_rx_gateway_mac_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.gateway_ping_rx
    ADD CONSTRAINT gateway_ping_rx_gateway_mac_fkey FOREIGN KEY (gateway_mac) REFERENCES public.gateway(mac) ON DELETE CASCADE;


--
-- TOC entry 3600 (class 2606 OID 16910)
-- Name: gateway_ping_rx gateway_ping_rx_ping_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.gateway_ping_rx
    ADD CONSTRAINT gateway_ping_rx_ping_id_fkey FOREIGN KEY (ping_id) REFERENCES public.gateway_ping(id) ON DELETE CASCADE;


--
-- TOC entry 3608 (class 2606 OID 17151)
-- Name: gateway_profile gateway_profile_network_server_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.gateway_profile
    ADD CONSTRAINT gateway_profile_network_server_id_fkey FOREIGN KEY (network_server_id) REFERENCES public.network_server(id);


--
-- TOC entry 3596 (class 2606 OID 17469)
-- Name: gateway gateway_service_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_service_profile_id_fkey FOREIGN KEY (service_profile_id) REFERENCES public.service_profile(service_profile_id);


--
-- TOC entry 3597 (class 2606 OID 16874)
-- Name: integration integration_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.integration
    ADD CONSTRAINT integration_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.application(id) ON DELETE CASCADE;


--
-- TOC entry 3609 (class 2606 OID 17479)
-- Name: multicast_group multicast_group_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.multicast_group
    ADD CONSTRAINT multicast_group_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.application(id) ON DELETE CASCADE;


--
-- TOC entry 3590 (class 2606 OID 16824)
-- Name: organization_user organization_user_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.organization_user
    ADD CONSTRAINT organization_user_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- TOC entry 3591 (class 2606 OID 16819)
-- Name: organization_user organization_user_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.organization_user
    ADD CONSTRAINT organization_user_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- TOC entry 3601 (class 2606 OID 16960)
-- Name: service_profile service_profile_network_server_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.service_profile
    ADD CONSTRAINT service_profile_network_server_id_fkey FOREIGN KEY (network_server_id) REFERENCES public.network_server(id);


--
-- TOC entry 3602 (class 2606 OID 16955)
-- Name: service_profile service_profile_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_as
--

ALTER TABLE ONLY public.service_profile
    ADD CONSTRAINT service_profile_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id);


--
-- TOC entry 3786 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2026-05-18 18:29:26 -03

--
-- PostgreSQL database dump complete
--

\unrestrict fmGA6Q4gUy4fs9ajksMFz874I60U4eU4QITWZV6WpB5ryqSmkGE3HpxfQ2KmQ5n

