--
-- PostgreSQL database dump
--

\restrict j5cNAd0xWLvEJNqn3cY5lIwrsHTfbx8EjByeev3F7rOcFfeoRN3VbF97M8xPbgW

-- Dumped from database version 17.5 (Debian 17.5-1.pgdg130+1)
-- Dumped by pg_dump version 17.10 (Ubuntu 17.10-1.pgdg24.04+1)

-- Started on 2026-05-18 18:39:14 -03

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

DROP DATABASE IF EXISTS chirpstack;
--
-- TOC entry 3786 (class 1262 OID 16385)
-- Name: chirpstack; Type: DATABASE; Schema: -; Owner: chirpstack
--

CREATE DATABASE chirpstack WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE chirpstack OWNER TO chirpstack;

\unrestrict j5cNAd0xWLvEJNqn3cY5lIwrsHTfbx8EjByeev3F7rOcFfeoRN3VbF97M8xPbgW
\connect chirpstack
\restrict j5cNAd0xWLvEJNqn3cY5lIwrsHTfbx8EjByeev3F7rOcFfeoRN3VbF97M8xPbgW

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
-- TOC entry 219 (class 1259 OID 16599)
-- Name: __diesel_schema_migrations; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.__diesel_schema_migrations (
    version character varying(50) NOT NULL,
    run_on timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.__diesel_schema_migrations OWNER TO chirpstack;

--
-- TOC entry 226 (class 1259 OID 16680)
-- Name: api_key; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.api_key (
    id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    is_admin boolean NOT NULL,
    tenant_id uuid
);


ALTER TABLE public.api_key OWNER TO chirpstack;

--
-- TOC entry 224 (class 1259 OID 16654)
-- Name: application; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.application (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    description text NOT NULL,
    mqtt_tls_cert bytea,
    tags jsonb NOT NULL
);


ALTER TABLE public.application OWNER TO chirpstack;

--
-- TOC entry 225 (class 1259 OID 16668)
-- Name: application_integration; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.application_integration (
    application_id uuid NOT NULL,
    kind character varying(20) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    configuration jsonb NOT NULL
);


ALTER TABLE public.application_integration OWNER TO chirpstack;

--
-- TOC entry 228 (class 1259 OID 16706)
-- Name: device; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.device (
    dev_eui bytea NOT NULL,
    application_id uuid NOT NULL,
    device_profile_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    last_seen_at timestamp with time zone,
    scheduler_run_after timestamp with time zone,
    name character varying(100) NOT NULL,
    description text NOT NULL,
    external_power_source boolean NOT NULL,
    battery_level numeric(5,2),
    margin integer,
    dr smallint,
    latitude double precision,
    longitude double precision,
    altitude real,
    dev_addr bytea,
    enabled_class character(1) NOT NULL,
    skip_fcnt_check boolean NOT NULL,
    is_disabled boolean NOT NULL,
    tags jsonb NOT NULL,
    variables jsonb NOT NULL,
    join_eui bytea NOT NULL,
    secondary_dev_addr bytea,
    device_session bytea,
    app_layer_params jsonb NOT NULL,
    f_cnt_up bigint NOT NULL
);


ALTER TABLE public.device OWNER TO chirpstack;

--
-- TOC entry 229 (class 1259 OID 16729)
-- Name: device_keys; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.device_keys (
    dev_eui bytea NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    nwk_key bytea NOT NULL,
    app_key bytea NOT NULL,
    dev_nonces jsonb NOT NULL,
    join_nonce integer NOT NULL,
    gen_app_key bytea NOT NULL
);


ALTER TABLE public.device_keys OWNER TO chirpstack;

--
-- TOC entry 227 (class 1259 OID 16691)
-- Name: device_profile; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.device_profile (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    region character varying(10) NOT NULL,
    mac_version character varying(10) NOT NULL,
    reg_params_revision character varying(20) NOT NULL,
    adr_algorithm_id character varying(100) NOT NULL,
    payload_codec_runtime character varying(20) NOT NULL,
    uplink_interval integer NOT NULL,
    device_status_req_interval integer NOT NULL,
    supports_otaa boolean NOT NULL,
    supports_class_b boolean NOT NULL,
    supports_class_c boolean NOT NULL,
    tags jsonb NOT NULL,
    payload_codec_script text NOT NULL,
    flush_queue_on_activate boolean NOT NULL,
    description text NOT NULL,
    measurements jsonb NOT NULL,
    auto_detect_measurements boolean NOT NULL,
    region_config_id character varying(100),
    allow_roaming boolean NOT NULL,
    rx1_delay smallint NOT NULL,
    abp_params jsonb,
    class_b_params jsonb,
    class_c_params jsonb,
    relay_params jsonb,
    app_layer_params jsonb NOT NULL
);


ALTER TABLE public.device_profile OWNER TO chirpstack;

--
-- TOC entry 234 (class 1259 OID 16808)
-- Name: device_profile_template; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.device_profile_template (
    id text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    description text NOT NULL,
    vendor character varying(100) NOT NULL,
    firmware character varying(100) NOT NULL,
    region character varying(10) NOT NULL,
    mac_version character varying(10) NOT NULL,
    reg_params_revision character varying(20) NOT NULL,
    adr_algorithm_id character varying(100) NOT NULL,
    payload_codec_runtime character varying(20) NOT NULL,
    payload_codec_script text NOT NULL,
    uplink_interval integer NOT NULL,
    device_status_req_interval integer NOT NULL,
    flush_queue_on_activate boolean NOT NULL,
    supports_otaa boolean NOT NULL,
    supports_class_b boolean NOT NULL,
    supports_class_c boolean NOT NULL,
    class_b_timeout integer NOT NULL,
    class_b_ping_slot_periodicity integer NOT NULL,
    class_b_ping_slot_dr smallint NOT NULL,
    class_b_ping_slot_freq bigint NOT NULL,
    class_c_timeout integer NOT NULL,
    abp_rx1_delay smallint NOT NULL,
    abp_rx1_dr_offset smallint NOT NULL,
    abp_rx2_dr smallint NOT NULL,
    abp_rx2_freq bigint NOT NULL,
    tags jsonb NOT NULL,
    measurements jsonb NOT NULL,
    auto_detect_measurements boolean NOT NULL
);


ALTER TABLE public.device_profile_template OWNER TO chirpstack;

--
-- TOC entry 230 (class 1259 OID 16741)
-- Name: device_queue_item; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.device_queue_item (
    id uuid NOT NULL,
    dev_eui bytea NOT NULL,
    created_at timestamp with time zone NOT NULL,
    f_port smallint NOT NULL,
    confirmed boolean NOT NULL,
    data bytea NOT NULL,
    is_pending boolean NOT NULL,
    f_cnt_down bigint,
    timeout_after timestamp with time zone,
    is_encrypted boolean NOT NULL,
    expires_at timestamp with time zone
);


ALTER TABLE public.device_queue_item OWNER TO chirpstack;

--
-- TOC entry 238 (class 1259 OID 16924)
-- Name: fuota_deployment; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.fuota_deployment (
    id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    name character varying(100) NOT NULL,
    application_id uuid NOT NULL,
    device_profile_id uuid NOT NULL,
    multicast_addr bytea NOT NULL,
    multicast_key bytea NOT NULL,
    multicast_group_type character(1) NOT NULL,
    multicast_class_c_scheduling_type character varying(20) NOT NULL,
    multicast_dr smallint NOT NULL,
    multicast_class_b_ping_slot_periodicity smallint NOT NULL,
    multicast_frequency bigint NOT NULL,
    multicast_timeout smallint NOT NULL,
    multicast_session_start timestamp with time zone,
    multicast_session_end timestamp with time zone,
    unicast_max_retry_count smallint NOT NULL,
    fragmentation_fragment_size smallint NOT NULL,
    fragmentation_redundancy_percentage smallint NOT NULL,
    fragmentation_session_index smallint NOT NULL,
    fragmentation_matrix smallint NOT NULL,
    fragmentation_block_ack_delay smallint NOT NULL,
    fragmentation_descriptor bytea NOT NULL,
    request_fragmentation_session_status character varying(20) NOT NULL,
    payload bytea NOT NULL,
    on_complete_set_device_tags jsonb NOT NULL
);


ALTER TABLE public.fuota_deployment OWNER TO chirpstack;

--
-- TOC entry 239 (class 1259 OID 16941)
-- Name: fuota_deployment_device; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.fuota_deployment_device (
    fuota_deployment_id uuid NOT NULL,
    dev_eui bytea NOT NULL,
    created_at timestamp with time zone NOT NULL,
    completed_at timestamp with time zone,
    mc_group_setup_completed_at timestamp with time zone,
    mc_session_completed_at timestamp with time zone,
    frag_session_setup_completed_at timestamp with time zone,
    frag_status_completed_at timestamp with time zone,
    error_msg text NOT NULL
);


ALTER TABLE public.fuota_deployment_device OWNER TO chirpstack;

--
-- TOC entry 240 (class 1259 OID 16958)
-- Name: fuota_deployment_gateway; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.fuota_deployment_gateway (
    fuota_deployment_id uuid NOT NULL,
    gateway_id bytea NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.fuota_deployment_gateway OWNER TO chirpstack;

--
-- TOC entry 241 (class 1259 OID 16975)
-- Name: fuota_deployment_job; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.fuota_deployment_job (
    fuota_deployment_id uuid NOT NULL,
    job character varying(20) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    completed_at timestamp with time zone,
    max_retry_count smallint NOT NULL,
    attempt_count smallint NOT NULL,
    scheduler_run_after timestamp with time zone NOT NULL,
    warning_msg text NOT NULL,
    error_msg text NOT NULL
);


ALTER TABLE public.fuota_deployment_job OWNER TO chirpstack;

--
-- TOC entry 223 (class 1259 OID 16638)
-- Name: gateway; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.gateway (
    gateway_id bytea NOT NULL,
    tenant_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    last_seen_at timestamp with time zone,
    name character varying(100) NOT NULL,
    description text NOT NULL,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    altitude real NOT NULL,
    stats_interval_secs integer NOT NULL,
    tls_certificate bytea,
    tags jsonb NOT NULL,
    properties jsonb NOT NULL
);


ALTER TABLE public.gateway OWNER TO chirpstack;

--
-- TOC entry 231 (class 1259 OID 16756)
-- Name: multicast_group; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.multicast_group (
    id uuid NOT NULL,
    application_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    region character varying(10) NOT NULL,
    mc_addr bytea NOT NULL,
    mc_nwk_s_key bytea NOT NULL,
    mc_app_s_key bytea NOT NULL,
    f_cnt bigint NOT NULL,
    group_type character(1) NOT NULL,
    dr smallint NOT NULL,
    frequency bigint NOT NULL,
    class_b_ping_slot_periodicity smallint NOT NULL,
    class_c_scheduling_type character varying(20) NOT NULL
);


ALTER TABLE public.multicast_group OWNER TO chirpstack;

--
-- TOC entry 232 (class 1259 OID 16770)
-- Name: multicast_group_device; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.multicast_group_device (
    multicast_group_id uuid NOT NULL,
    dev_eui bytea NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.multicast_group_device OWNER TO chirpstack;

--
-- TOC entry 235 (class 1259 OID 16829)
-- Name: multicast_group_gateway; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.multicast_group_gateway (
    multicast_group_id uuid NOT NULL,
    gateway_id bytea NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.multicast_group_gateway OWNER TO chirpstack;

--
-- TOC entry 233 (class 1259 OID 16787)
-- Name: multicast_group_queue_item; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.multicast_group_queue_item (
    id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    scheduler_run_after timestamp with time zone NOT NULL,
    multicast_group_id uuid NOT NULL,
    gateway_id bytea NOT NULL,
    f_cnt bigint NOT NULL,
    f_port smallint NOT NULL,
    data bytea NOT NULL,
    emit_at_time_since_gps_epoch bigint,
    expires_at timestamp with time zone
);


ALTER TABLE public.multicast_group_queue_item OWNER TO chirpstack;

--
-- TOC entry 236 (class 1259 OID 16870)
-- Name: relay_device; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.relay_device (
    relay_dev_eui bytea NOT NULL,
    dev_eui bytea NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.relay_device OWNER TO chirpstack;

--
-- TOC entry 237 (class 1259 OID 16905)
-- Name: relay_gateway; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.relay_gateway (
    tenant_id uuid NOT NULL,
    relay_id bytea NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    last_seen_at timestamp with time zone,
    name character varying(100) NOT NULL,
    description text NOT NULL,
    stats_interval_secs integer NOT NULL,
    region_config_id character varying(100) NOT NULL
);


ALTER TABLE public.relay_gateway OWNER TO chirpstack;

--
-- TOC entry 221 (class 1259 OID 16614)
-- Name: tenant; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.tenant (
    id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    description text NOT NULL,
    can_have_gateways boolean NOT NULL,
    max_device_count integer NOT NULL,
    max_gateway_count integer NOT NULL,
    private_gateways_up boolean NOT NULL,
    private_gateways_down boolean NOT NULL,
    tags jsonb NOT NULL
);


ALTER TABLE public.tenant OWNER TO chirpstack;

--
-- TOC entry 222 (class 1259 OID 16622)
-- Name: tenant_user; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.tenant_user (
    tenant_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_admin boolean NOT NULL,
    is_device_admin boolean NOT NULL,
    is_gateway_admin boolean NOT NULL
);


ALTER TABLE public.tenant_user OWNER TO chirpstack;

--
-- TOC entry 220 (class 1259 OID 16605)
-- Name: user; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public."user" (
    id uuid NOT NULL,
    external_id text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_admin boolean NOT NULL,
    is_active boolean NOT NULL,
    email text NOT NULL,
    email_verified boolean NOT NULL,
    password_hash character varying(200) NOT NULL,
    note text NOT NULL
);


ALTER TABLE public."user" OWNER TO chirpstack;

--
-- TOC entry 3758 (class 0 OID 16599)
-- Dependencies: 219
-- Data for Name: __diesel_schema_migrations; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.__diesel_schema_migrations (version, run_on) FROM stdin;
00000000000000	2026-05-01 16:21:10.253969
20220426153628	2026-05-01 16:21:10.721962
20220428071028	2026-05-01 16:21:10.741168
20220511084032	2026-05-01 16:21:10.743615
20220614130020	2026-05-01 16:21:10.842915
20221102090533	2026-05-01 16:21:10.846269
20230103201442	2026-05-01 16:21:10.848999
20230112130153	2026-05-01 16:21:10.851293
20230206135050	2026-05-01 16:21:10.853343
20230213103316	2026-05-01 16:21:10.874949
20230216091535	2026-05-01 16:21:10.877461
20230925105457	2026-05-01 16:21:10.909949
20231019142614	2026-05-01 16:21:10.912357
20231122120700	2026-05-01 16:21:10.932356
20240207083424	2026-05-01 16:21:10.934942
20240326134652	2026-05-01 16:21:10.947875
20240430103242	2026-05-01 16:21:11.025275
20240613122655	2026-05-01 16:21:11.028298
20240916123034	2026-05-01 16:21:11.054123
20241112135745	2026-05-01 16:21:11.056706
20250113152218	2026-05-01 16:21:11.109292
20250121093745	2026-05-01 16:21:11.140522
20250605100843	2026-05-01 16:21:11.244598
20250804085822	2026-05-01 16:21:11.246899
20251001085546	2026-05-01 16:21:11.252227
\.


--
-- TOC entry 3765 (class 0 OID 16680)
-- Dependencies: 226
-- Data for Name: api_key; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.api_key (id, created_at, name, is_admin, tenant_id) FROM stdin;
\.


--
-- TOC entry 3763 (class 0 OID 16654)
-- Dependencies: 224
-- Data for Name: application; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.application (id, tenant_id, created_at, updated_at, name, description, mqtt_tls_cert, tags) FROM stdin;
56560a65-2fb8-444c-a1ee-bd0ee4be0946	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-04 02:04:59.496447+00	2026-05-04 02:04:59.496447+00	devices_au915	Frequency Plan AU915	\N	{}
\.


--
-- TOC entry 3764 (class 0 OID 16668)
-- Dependencies: 225
-- Data for Name: application_integration; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.application_integration (application_id, kind, created_at, updated_at, configuration) FROM stdin;
\.


--
-- TOC entry 3767 (class 0 OID 16706)
-- Dependencies: 228
-- Data for Name: device; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device (dev_eui, application_id, device_profile_id, created_at, updated_at, last_seen_at, scheduler_run_after, name, description, external_power_source, battery_level, margin, dr, latitude, longitude, altitude, dev_addr, enabled_class, skip_fcnt_check, is_disabled, tags, variables, join_eui, secondary_dev_addr, device_session, app_layer_params, f_cnt_up) FROM stdin;
\\x08fdbe4bc604e8f8	56560a65-2fb8-444c-a1ee-bd0ee4be0946	1bbfac1d-4e6f-44b4-8e48-aae6dcf6c591	2026-05-10 13:53:34.770399+00	2026-05-11 21:06:02.986362+00	2026-05-12 13:43:33.420294+00	2026-05-12 13:43:38.415883+00	ESP32 RF95W (ABP)	ESP32 with RF95W (ABP)	f	\N	6	5	\N	\N	\N	\\x00aa88ca	A	t	f	{}	{}	\\x0000000000000000	\N	\\x120400aa88ca20032a10151f7779d7aaee422a74568380db70453210151f7779d7aaee422a74568380db70453a10151f7779d7aaee422a74568380db704542121210fd91d55dce3af1023093e289a1d9f3df5001680170018001088801a0e1a1b80392010908090a0b0c0d0e0f41b80101c80105f20114084d1500002041200528e7ffffffffffffffff01f20114084e15cdcc5c41200528e4ffffffffffffffff0182020c0883dd8cd00610bcd8bcd202c2020761753931355f31	{"ts004_session_cnt": [0, 0, 0, 0]}	79
\\xf38df5e5a31e63de	56560a65-2fb8-444c-a1ee-bd0ee4be0946	cff3ab28-afa3-4909-8958-e01ab4984a3b	2026-05-04 02:06:34.517515+00	2026-05-10 15:19:01.527258+00	2026-05-18 21:39:05.135151+00	2026-05-18 21:39:10.128555+00	ESP32 RF95W (OTAA)	ESP32 with RF95W (OTAA)	f	\N	6	2	\N	\N	\N	\\x007ea68e	A	f	f	{}	{}	\\xc7102ce6a134f6b2	\N	\\x1204007ea68e20032a103b0d294f96511be99e810775ee78177f32103b0d294f96511be99e810775ee78177f3a103b0d294f96511be99e810775ee78177f42121210288743626c160893fc8035f1f7263335500570018001088801a0e1a1b80392010908090a0b0c0d0e0f41b80101c80102f2011508f8121500006841200428e8ffffffffffffffff01f2011508f9121500004841200428e6ffffffffffffffff01f2011508fa121500004841200428e7ffffffffffffffff01f2011508fb121500004041200428e6ffffffffffffffff01f2011508fc12159a99f940200428e7ffffffffffffffff01f2011508fd121500004841200428ecffffffffffffffff01f2011508fe121500004041200428e4ffffffffffffffff01f2011508ff121533334341200428ebffffffffffffffff01f2011508801315cdcc4c41200428e7ffffffffffffffff01f2011508811315cdcc2c41200428eaffffffffffffffff01f201150882131500004841200428e7ffffffffffffffff01f201150883131500003041200428eaffffffffffffffff01f201150884131500004841200428eaffffffffffffffff01f201150885131500003041200428e9ffffffffffffffff01f2011508861315cdcc3c41200428ebffffffffffffffff01f201150887131533333341200428e9ffffffffffffffff01f201150888131533335341200428e6ffffffffffffffff01f201150889131533333341200428eaffffffffffffffff01f20115088a131500004841200428e6ffffffffffffffff01f20115088b131500004041200428eaffffffffffffffff0182020c08e19aacd00610af97b2c702c2020761753931355f31	{"ts004_session_cnt": [0, 0, 0, 0]}	2444
\.


--
-- TOC entry 3768 (class 0 OID 16729)
-- Dependencies: 229
-- Data for Name: device_keys; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device_keys (dev_eui, created_at, updated_at, nwk_key, app_key, dev_nonces, join_nonce, gen_app_key) FROM stdin;
\\xf38df5e5a31e63de	2026-05-04 02:06:50.902336+00	2026-05-18 13:00:11.631287+00	\\x6fc57c4cda46ddc502bcb7855e4e94ae	\\x00000000000000000000000000000000	{"c7102ce6a134f6b2": [39887, 32611, 9324, 51147, 27064, 9067, 2140, 3264, 2337, 35373, 2760, 522, 42945, 16868, 4147, 26038, 39257, 13414, 26958, 12550, 19365, 56516, 53749, 29433, 27104, 46854, 11035, 22905, 55745, 55489, 51674, 48135, 23659, 26471, 38952, 10916, 59466, 21142, 35911, 5254, 14405, 15793, 51203, 11815, 41815, 3520, 18663, 41650, 47894, 50588, 24383, 5622, 9717, 1272, 20703, 49800, 15851, 45942, 63845, 41080, 40483, 12185, 13121, 45355, 24047, 59808, 33980, 26241]}	68	\\x00000000000000000000000000000000
\.


--
-- TOC entry 3766 (class 0 OID 16691)
-- Dependencies: 227
-- Data for Name: device_profile; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device_profile (id, tenant_id, created_at, updated_at, name, region, mac_version, reg_params_revision, adr_algorithm_id, payload_codec_runtime, uplink_interval, device_status_req_interval, supports_otaa, supports_class_b, supports_class_c, tags, payload_codec_script, flush_queue_on_activate, description, measurements, auto_detect_measurements, region_config_id, allow_roaming, rx1_delay, abp_params, class_b_params, class_c_params, relay_params, app_layer_params) FROM stdin;
6d427ef3-0285-40b6-97ee-419cd1454da6	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-10 14:33:18.153052+00	2026-05-10 14:33:18.153052+00	Devide Profile - AU915_0 - 1.0.3 - A (OTAA)	AU915	1.0.3	A	default	NONE	3600	1	t	f	t	{}	/**\n * Decode uplink function\n * \n * @param {object} input\n * @param {number[]} input.bytes Byte array containing the uplink payload, e.g. [255, 230, 255, 0]\n * @param {number} input.fPort Uplink fPort.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{data: object, errors: string[], warnings: string[]}}\n * An object containing:\n * - data: Object representing the decoded payload.\n * - errors: An array of errors (optional).\n * - warnings: An array of warnings (optional).\n */\nfunction decodeUplink(input) {\n  return {\n    data: {\n      temp: 22.5,\n    }\n  };\n}\n\n/**\n * Encode downlink function.\n * \n * @param {object} input\n * @param {object} input.data Object representing the payload that must be encoded.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{bytes: number[], fPort: number, errors: string[], warnings: string[]}}\n * An object containing:\n * - bytes: Byte array containing the downlink payload.\n * - fPort: The downlink LoRaWAN fPort.\n * - errors: An array of errors (optional).\n * - warnings: An array of warnings (optional).\n */\nfunction encodeDownlink(input) {\n  return {\n    fPort: 10,\n    bytes: [225, 230, 255, 0],\n  };\n}\n	t	Devide Profile Region AU915 - Region configuration 0 - MAC version LoRaWAN 1.0.3 - Regional parameters revision A (OTAA)	{}	t	au915_0	f	0	\N	\N	{"timeout": 5}	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}
b9f5f095-7bcc-427f-8381-b9dd8eba0e1a	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:54:50.69657+00	2026-05-11 18:38:41.607836+00	Devide Profile - AU915_0 - 1.0.3 - A (ABP)	AU915	1.0.3	A	default	NONE	3600	1	f	f	t	{}	/**\n * Decode uplink function\n * \n * @param {object} input\n * @param {number[]} input.bytes Byte array containing the uplink payload, e.g. [255, 230, 255, 0]\n * @param {number} input.fPort Uplink fPort.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{data: object, errors: string[], warnings: string[]}}\n * An object containing:\n * - data: Object representing the decoded payload.\n * - errors: An array of errors (optional).\n * - warnings: An array of warnings (optional).\n */\nfunction decodeUplink(input) {\n  return {\n    data: {\n      temp: 22.5,\n    }\n  };\n}\n\n/**\n * Encode downlink function.\n * \n * @param {object} input\n * @param {object} input.data Object representing the payload that must be encoded.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{bytes: number[], fPort: number, errors: string[], warnings: string[]}}\n * An object containing:\n * - bytes: Byte array containing the downlink payload.\n * - fPort: The downlink LoRaWAN fPort.\n * - errors: An array of errors (optional).\n * - warnings: An array of warnings (optional).\n */\nfunction encodeDownlink(input) {\n  return {\n    fPort: 10,\n    bytes: [225, 230, 255, 0],\n  };\n}\n	t	Devide Profile Region AU915 - Region configuration 0 - MAC version LoRaWAN 1.0.3 - Regional parameters revision A (ABP)	{}	t	au915_0	f	0	{"rx2_dr": 8, "rx2_freq": 923300000, "rx1_delay": 1, "rx1_dr_offset": 0}	\N	{"timeout": 5}	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}
f984c66c-b3a6-4edb-85bb-ea5617d036a4	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:55:26.187824+00	2026-05-11 18:39:06.917039+00	Devide Profile - AU915_1 - 1.0.3 - A (ABP)	AU915	1.0.3	A	default	NONE	3600	1	f	f	t	{}	/**\n * Decode uplink function\n * \n * @param {object} input\n * @param {number[]} input.bytes Byte array containing the uplink payload, e.g. [255, 230, 255, 0]\n * @param {number} input.fPort Uplink fPort.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{data: object, errors: string[], warnings: string[]}}\n * An object containing:\n * - data: Object representing the decoded payload.\n * - errors: An array of errors (optional).\n * - warnings: An array of warnings (optional).\n */\nfunction decodeUplink(input) {\n  return {\n    data: {\n      temp: 22.5,\n    }\n  };\n}\n\n/**\n * Encode downlink function.\n * \n * @param {object} input\n * @param {object} input.data Object representing the payload that must be encoded.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{bytes: number[], fPort: number, errors: string[], warnings: string[]}}\n * An object containing:\n * - bytes: Byte array containing the downlink payload.\n * - fPort: The downlink LoRaWAN fPort.\n * - errors: An array of errors (optional).\n * - warnings: An array of warnings (optional).\n */\nfunction encodeDownlink(input) {\n  return {\n    fPort: 10,\n    bytes: [225, 230, 255, 0],\n  };\n}\n	t	Devide Profile Region AU915 - Region configuration 1 - MAC version LoRaWAN 1.0.3 - Regional parameters revision A (ABP)	{}	t	au915_1	f	0	{"rx2_dr": 8, "rx2_freq": 923300000, "rx1_delay": 1, "rx1_dr_offset": 0}	\N	{"timeout": 5}	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}
0cc8dba0-cbea-4784-b769-b0dcf0dab8ff	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-10 14:34:14.531822+00	2026-05-10 14:34:14.531822+00	Devide Profile - AU915_0 - 1.0.3 - B (OTAA)	AU915	1.0.3	B	default	NONE	3600	1	t	f	t	{}	/**\n * Decode uplink function\n * \n * @param {object} input\n * @param {number[]} input.bytes Byte array containing the uplink payload, e.g. [255, 230, 255, 0]\n * @param {number} input.fPort Uplink fPort.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{data: object, errors: string[], warnings: string[]}}\n * An object containing:\n * - data: Object representing the decoded payload.\n * - errors: An array of errors (optional).\n * - warnings: An array of warnings (optional).\n */\nfunction decodeUplink(input) {\n  return {\n    data: {\n      temp: 22.5,\n    }\n  };\n}\n\n/**\n * Encode downlink function.\n * \n * @param {object} input\n * @param {object} input.data Object representing the payload that must be encoded.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{bytes: number[], fPort: number, errors: string[], warnings: string[]}}\n * An object containing:\n * - bytes: Byte array containing the downlink payload.\n * - fPort: The downlink LoRaWAN fPort.\n * - errors: An array of errors (optional).\n * - warnings: An array of warnings (optional).\n */\nfunction encodeDownlink(input) {\n  return {\n    fPort: 10,\n    bytes: [225, 230, 255, 0],\n  };\n}\n	t	Devide Profile Region AU915 - Region configuration 0 - MAC version LoRaWAN 1.0.3 - Regional parameters revision B (OTAA)	{}	t	au915_0	f	0	\N	\N	{"timeout": 5}	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}
a82611dc-b236-422c-a1e5-87c155cfb3d7	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-10 14:33:45.174072+00	2026-05-10 14:33:45.174072+00	Devide Profile - AU915_1 - 1.0.3 - A (OTAA)	AU915	1.0.3	A	default	NONE	3600	1	t	f	t	{}	/**\n * Decode uplink function\n * \n * @param {object} input\n * @param {number[]} input.bytes Byte array containing the uplink payload, e.g. [255, 230, 255, 0]\n * @param {number} input.fPort Uplink fPort.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{data: object, errors: string[], warnings: string[]}}\n * An object containing:\n * - data: Object representing the decoded payload.\n * - errors: An array of errors (optional).\n * - warnings: An array of warnings (optional).\n */\nfunction decodeUplink(input) {\n  return {\n    data: {\n      temp: 22.5,\n    }\n  };\n}\n\n/**\n * Encode downlink function.\n * \n * @param {object} input\n * @param {object} input.data Object representing the payload that must be encoded.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{bytes: number[], fPort: number, errors: string[], warnings: string[]}}\n * An object containing:\n * - bytes: Byte array containing the downlink payload.\n * - fPort: The downlink LoRaWAN fPort.\n * - errors: An array of errors (optional).\n * - warnings: An array of warnings (optional).\n */\nfunction encodeDownlink(input) {\n  return {\n    fPort: 10,\n    bytes: [225, 230, 255, 0],\n  };\n}\n	t	Devide Profile Region AU915 - Region configuration 1 - MAC version LoRaWAN 1.0.3 - Regional parameters revision A (OTAA)	{}	t	au915_1	f	0	\N	\N	{"timeout": 5}	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}
e630fede-3319-4974-931d-6bc00ee12c15	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:55:57.800665+00	2026-05-11 18:38:51.858305+00	Devide Profile - AU915_0 - 1.0.3 - B (ABP)	AU915	1.0.3	B	default	NONE	3600	1	f	f	t	{}	/**\n * Decode uplink function\n * \n * @param {object} input\n * @param {number[]} input.bytes Byte array containing the uplink payload, e.g. [255, 230, 255, 0]\n * @param {number} input.fPort Uplink fPort.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{data: object, errors: string[], warnings: string[]}}\n * An object containing:\n * - data: Object representing the decoded payload.\n * - errors: An array of errors (optional).\n * - warnings: An array of warnings (optional).\n */\nfunction decodeUplink(input) {\n  return {\n    data: {\n      temp: 22.5,\n    }\n  };\n}\n\n/**\n * Encode downlink function.\n * \n * @param {object} input\n * @param {object} input.data Object representing the payload that must be encoded.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{bytes: number[], fPort: number, errors: string[], warnings: string[]}}\n * An object containing:\n * - bytes: Byte array containing the downlink payload.\n * - fPort: The downlink LoRaWAN fPort.\n * - errors: An array of errors (optional).\n * - warnings: An array of warnings (optional).\n */\nfunction encodeDownlink(input) {\n  return {\n    fPort: 10,\n    bytes: [225, 230, 255, 0],\n  };\n}\n	t	Devide Profile Region AU915 - Region configuration 0 - MAC version LoRaWAN 1.0.3 - Regional parameters revision B (ABP)	{}	t	au915_0	f	0	{"rx2_dr": 8, "rx2_freq": 923300000, "rx1_delay": 1, "rx1_dr_offset": 0}	\N	{"timeout": 5}	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}
cff3ab28-afa3-4909-8958-e01ab4984a3b	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-10 14:34:42.556927+00	2026-05-10 15:23:39.62467+00	Devide Profile - AU915_1 - 1.0.3 - B (OTAA)	AU915	1.0.3	B	default	NONE	3600	1	t	f	f	{}	/**\n * Decode uplink function\n * \n * @param {object} input\n * @param {number[]} input.bytes Byte array containing the uplink payload, e.g. [255, 230, 255, 0]\n * @param {number} input.fPort Uplink fPort.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{data: object, errors: string[], warnings: string[]}}\n * An object containing:\n * - data: Object representing the decoded payload.\n * - errors: An array of errors (optional).\n * - warnings: An array of warnings (optional).\n */\nfunction decodeUplink(input) {\n  return {\n    data: {\n      temp: 22.5,\n    }\n  };\n}\n\n/**\n * Encode downlink function.\n * \n * @param {object} input\n * @param {object} input.data Object representing the payload that must be encoded.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{bytes: number[], fPort: number, errors: string[], warnings: string[]}}\n * An object containing:\n * - bytes: Byte array containing the downlink payload.\n * - fPort: The downlink LoRaWAN fPort.\n * - errors: An array of errors (optional).\n * - warnings: An array of warnings (optional).\n */\nfunction encodeDownlink(input) {\n  return {\n    fPort: 10,\n    bytes: [225, 230, 255, 0],\n  };\n}\n	t	Devide Profile Region AU915 - Region configuration 1 - MAC version LoRaWAN 1.0.3 - Regional parameters revision B (OTAA)	{}	t	au915_1	f	0	\N	\N	\N	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}
1bbfac1d-4e6f-44b4-8e48-aae6dcf6c591	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:56:31.807982+00	2026-05-11 19:21:04.289842+00	Devide Profile - AU915_1 - 1.0.3 - B (ABP)	AU915	1.0.3	B	default	NONE	3600	1	f	f	f	{}	/**\n * Decode uplink function\n * \n * @param {object} input\n * @param {number[]} input.bytes Byte array containing the uplink payload, e.g. [255, 230, 255, 0]\n * @param {number} input.fPort Uplink fPort.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{data: object, errors: string[], warnings: string[]}}\n * An object containing:\n * - data: Object representing the decoded payload.\n * - errors: An array of errors (optional).\n * - warnings: An array of warnings (optional).\n */\nfunction decodeUplink(input) {\n  return {\n    data: {\n      temp: 22.5,\n    }\n  };\n}\n\n/**\n * Encode downlink function.\n * \n * @param {object} input\n * @param {object} input.data Object representing the payload that must be encoded.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{bytes: number[], fPort: number, errors: string[], warnings: string[]}}\n * An object containing:\n * - bytes: Byte array containing the downlink payload.\n * - fPort: The downlink LoRaWAN fPort.\n * - errors: An array of errors (optional).\n * - warnings: An array of warnings (optional).\n */\nfunction encodeDownlink(input) {\n  return {\n    fPort: 10,\n    bytes: [225, 230, 255, 0],\n  };\n}\n	t	Devide Profile Region AU915 - Region configuration 1 - MAC version LoRaWAN 1.0.3 - Regional parameters revision B (ABP)	{}	t	au915_1	f	0	{"rx2_dr": 8, "rx2_freq": 923300000, "rx1_delay": 1, "rx1_dr_offset": 0}	\N	\N	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}
\.


--
-- TOC entry 3773 (class 0 OID 16808)
-- Dependencies: 234
-- Data for Name: device_profile_template; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device_profile_template (id, created_at, updated_at, name, description, vendor, firmware, region, mac_version, reg_params_revision, adr_algorithm_id, payload_codec_runtime, payload_codec_script, uplink_interval, device_status_req_interval, flush_queue_on_activate, supports_otaa, supports_class_b, supports_class_c, class_b_timeout, class_b_ping_slot_periodicity, class_b_ping_slot_dr, class_b_ping_slot_freq, class_c_timeout, abp_rx1_delay, abp_rx1_dr_offset, abp_rx2_dr, abp_rx2_freq, tags, measurements, auto_detect_measurements) FROM stdin;
Devide_Profile_Template_AU915_1_0_3_A_ABP	2026-05-01 19:53:05.036281+00	2026-05-11 18:46:38.002088+00	Devide Profile Template - AU915 - 1.0.3 - A (ABP)	Devide Profile Template Region AU915 - MAC version LoRaWAN 1.0.3 - Regional parameters revision A (ABP)	AdailSilva-IoT	1.0	AU915	1.0.3	A	default	NONE	/**\n * Decode uplink function\n * \n * @param {object} input\n * @param {number[]} input.bytes Byte array containing the uplink payload, e.g. [255, 230, 255, 0]\n * @param {number} input.fPort Uplink fPort.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{data: object}} Object representing the decoded payload.\n */\nfunction decodeUplink(input) {\n  return {\n    data: {\n      // temp: 22.5\n    }\n  };\n}\n\n/**\n * Encode downlink function.\n * \n * @param {object} input\n * @param {object} input.data Object representing the payload that must be encoded.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{bytes: number[]}} Byte array containing the downlink payload.\n */\nfunction encodeDownlink(input) {\n  return {\n    // bytes: [225, 230, 255, 0]\n  };\n}\n	3600	1	t	f	f	t	0	0	0	0	5	1	0	8	923300000	{}	{}	t
Devide_Profile_Template_AU915_1_0_3_A_OTAA	2026-05-01 19:53:05.036281+00	2026-05-01 19:53:05.036281+00	Devide Profile Template - AU915 - 1.0.3 - A (OTAA)	Devide Profile Template Region AU915 - MAC version LoRaWAN 1.0.3 - Regional parameters revision A (OTAA)	AdailSilva-IoT	1.0	AU915	1.0.3	A	default	NONE	/**\n * Decode uplink function\n * \n * @param {object} input\n * @param {number[]} input.bytes Byte array containing the uplink payload, e.g. [255, 230, 255, 0]\n * @param {number} input.fPort Uplink fPort.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{data: object}} Object representing the decoded payload.\n */\nfunction decodeUplink(input) {\n  return {\n    data: {\n      // temp: 22.5\n    }\n  };\n}\n\n/**\n * Encode downlink function.\n * \n * @param {object} input\n * @param {object} input.data Object representing the payload that must be encoded.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{bytes: number[]}} Byte array containing the downlink payload.\n */\nfunction encodeDownlink(input) {\n  return {\n    // bytes: [225, 230, 255, 0]\n  };\n}\n	3600	1	t	t	f	t	0	0	0	0	5	0	0	0	0	{}	{}	t
Devide_Profile_Template_AU915_1_0_3_B_OTAA	2026-05-01 19:53:52.729292+00	2026-05-10 14:28:35.792411+00	Devide Profile Template - AU915 - 1.0.3 - B (OTAA)	Devide Profile Template Region AU915 - MAC version LoRaWAN 1.0.3 - Regional parameters revision B (OTAA)	AdailSilva-IoT	1.0	AU915	1.0.3	B	default	NONE	/**\n * Decode uplink function\n * \n * @param {object} input\n * @param {number[]} input.bytes Byte array containing the uplink payload, e.g. [255, 230, 255, 0]\n * @param {number} input.fPort Uplink fPort.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{data: object}} Object representing the decoded payload.\n */\nfunction decodeUplink(input) {\n  return {\n    data: {\n      // temp: 22.5\n    }\n  };\n}\n\n/**\n * Encode downlink function.\n * \n * @param {object} input\n * @param {object} input.data Object representing the payload that must be encoded.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{bytes: number[]}} Byte array containing the downlink payload.\n */\nfunction encodeDownlink(input) {\n  return {\n    // bytes: [225, 230, 255, 0]\n  };\n}\n	3600	1	t	t	f	t	0	0	0	0	5	0	0	0	0	{}	{}	t
Devide_Profile_Template_AU915_1_0_3_B_ABP	2026-05-01 19:53:52.729292+00	2026-05-11 18:46:45.616785+00	Devide Profile Template - AU915 - 1.0.3 - B (ABP)	Devide Profile Template Region AU915 - MAC version LoRaWAN 1.0.3 - Regional parameters revision B (ABP)	AdailSilva-IoT	1.0	AU915	1.0.3	B	default	NONE	/**\n * Decode uplink function\n * \n * @param {object} input\n * @param {number[]} input.bytes Byte array containing the uplink payload, e.g. [255, 230, 255, 0]\n * @param {number} input.fPort Uplink fPort.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{data: object}} Object representing the decoded payload.\n */\nfunction decodeUplink(input) {\n  return {\n    data: {\n      // temp: 22.5\n    }\n  };\n}\n\n/**\n * Encode downlink function.\n * \n * @param {object} input\n * @param {object} input.data Object representing the payload that must be encoded.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{bytes: number[]}} Byte array containing the downlink payload.\n */\nfunction encodeDownlink(input) {\n  return {\n    // bytes: [225, 230, 255, 0]\n  };\n}\n	3600	1	t	f	f	t	0	0	0	0	5	1	0	8	923300000	{}	{}	t
\.


--
-- TOC entry 3769 (class 0 OID 16741)
-- Dependencies: 230
-- Data for Name: device_queue_item; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device_queue_item (id, dev_eui, created_at, f_port, confirmed, data, is_pending, f_cnt_down, timeout_after, is_encrypted, expires_at) FROM stdin;
\.


--
-- TOC entry 3777 (class 0 OID 16924)
-- Dependencies: 238
-- Data for Name: fuota_deployment; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.fuota_deployment (id, created_at, updated_at, started_at, completed_at, name, application_id, device_profile_id, multicast_addr, multicast_key, multicast_group_type, multicast_class_c_scheduling_type, multicast_dr, multicast_class_b_ping_slot_periodicity, multicast_frequency, multicast_timeout, multicast_session_start, multicast_session_end, unicast_max_retry_count, fragmentation_fragment_size, fragmentation_redundancy_percentage, fragmentation_session_index, fragmentation_matrix, fragmentation_block_ack_delay, fragmentation_descriptor, request_fragmentation_session_status, payload, on_complete_set_device_tags) FROM stdin;
\.


--
-- TOC entry 3778 (class 0 OID 16941)
-- Dependencies: 239
-- Data for Name: fuota_deployment_device; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.fuota_deployment_device (fuota_deployment_id, dev_eui, created_at, completed_at, mc_group_setup_completed_at, mc_session_completed_at, frag_session_setup_completed_at, frag_status_completed_at, error_msg) FROM stdin;
\.


--
-- TOC entry 3779 (class 0 OID 16958)
-- Dependencies: 240
-- Data for Name: fuota_deployment_gateway; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.fuota_deployment_gateway (fuota_deployment_id, gateway_id, created_at) FROM stdin;
\.


--
-- TOC entry 3780 (class 0 OID 16975)
-- Dependencies: 241
-- Data for Name: fuota_deployment_job; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.fuota_deployment_job (fuota_deployment_id, job, created_at, completed_at, max_retry_count, attempt_count, scheduler_run_after, warning_msg, error_msg) FROM stdin;
\.


--
-- TOC entry 3762 (class 0 OID 16638)
-- Dependencies: 223
-- Data for Name: gateway; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.gateway (gateway_id, tenant_id, created_at, updated_at, last_seen_at, name, description, latitude, longitude, altitude, stats_interval_secs, tls_certificate, tags, properties) FROM stdin;
\\xb827ebfffe158993	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:57:52.319327+00	2026-05-01 19:57:52.319327+00	2026-05-18 21:38:55.702166+00	002-gtw-radioenge-001 | IP: 192.168.3.202	Radioenge RPi3-RD43HATGPS (Multi Channel)	-3.7304	-40.98799	784	30	\N	{}	{"region_config_id": "au915_1", "region_common_name": "AU915"}
\\xe45f01fffe10e12e	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:58:53.71564+00	2026-05-01 19:58:53.71564+00	2026-05-16 17:43:02.886344+00	005-gtw-elecrow-001 | IP: 192.168.18.205	Elecrow RPi4-GPS (Multi Channel)	51.482594	-0.007661	0	30	\N	{}	{"region_config_id": "au915_1", "region_common_name": "AU915"}
\\xb827ebfffe78ffce	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:58:29.414872+00	2026-05-01 19:58:29.414872+00	2026-05-18 21:38:55.818859+00	004-gtw-radioenge-003 | IP: 192.168.3.204	Radioenge RPi3-RD43HATGPS (Multi Channel)	-3.73042	-40.98799	778	30	\N	{}	{"region_config_id": "au915_1", "region_common_name": "AU915"}
\\xb827ebfffef81e69	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:58:11.271739+00	2026-05-01 19:58:11.271739+00	2026-05-18 21:39:03.47076+00	003-gtw-radioenge-002 | IP: 192.168.3.203	Radioenge RPi3-RD43HATGPS (Multi Channel)	-3.73042	-40.98799	780	30	\N	{}	{"region_config_id": "au915_1", "region_common_name": "AU915"}
\\xb827ebfffea04db6	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:57:06.297593+00	2026-05-01 19:57:06.297593+00	2026-05-18 21:39:10.488959+00	001-gtw-rak831-001 | IP: 192.168.3.201	RAK831 RPi3-GPS (Multi Channel)	-3.73041	-40.988	780	30	\N	{}	{"region_config_id": "au915_1", "region_common_name": "AU915"}
\\xa840411b7dcc4150	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:59:14.136588+00	2026-05-01 19:59:14.136588+00	\N	006-gtw-dragino_lg02-001 | IP: 10.130.1.1	Dragino LG02 (Dual Channel)	51.482594	-0.007661	0	30	\N	{}	{}
\.


--
-- TOC entry 3770 (class 0 OID 16756)
-- Dependencies: 231
-- Data for Name: multicast_group; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.multicast_group (id, application_id, created_at, updated_at, name, region, mc_addr, mc_nwk_s_key, mc_app_s_key, f_cnt, group_type, dr, frequency, class_b_ping_slot_periodicity, class_c_scheduling_type) FROM stdin;
\.


--
-- TOC entry 3771 (class 0 OID 16770)
-- Dependencies: 232
-- Data for Name: multicast_group_device; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.multicast_group_device (multicast_group_id, dev_eui, created_at) FROM stdin;
\.


--
-- TOC entry 3774 (class 0 OID 16829)
-- Dependencies: 235
-- Data for Name: multicast_group_gateway; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.multicast_group_gateway (multicast_group_id, gateway_id, created_at) FROM stdin;
\.


--
-- TOC entry 3772 (class 0 OID 16787)
-- Dependencies: 233
-- Data for Name: multicast_group_queue_item; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.multicast_group_queue_item (id, created_at, scheduler_run_after, multicast_group_id, gateway_id, f_cnt, f_port, data, emit_at_time_since_gps_epoch, expires_at) FROM stdin;
\.


--
-- TOC entry 3775 (class 0 OID 16870)
-- Dependencies: 236
-- Data for Name: relay_device; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.relay_device (relay_dev_eui, dev_eui, created_at) FROM stdin;
\.


--
-- TOC entry 3776 (class 0 OID 16905)
-- Dependencies: 237
-- Data for Name: relay_gateway; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.relay_gateway (tenant_id, relay_id, created_at, updated_at, last_seen_at, name, description, stats_interval_secs, region_config_id) FROM stdin;
\.


--
-- TOC entry 3760 (class 0 OID 16614)
-- Dependencies: 221
-- Data for Name: tenant; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.tenant (id, created_at, updated_at, name, description, can_have_gateways, max_device_count, max_gateway_count, private_gateways_up, private_gateways_down, tags) FROM stdin;
3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 16:21:10.253969+00	2026-05-08 16:23:47.31098+00	ChirpStack	AdailSilva-IoT	t	0	0	f	f	{}
\.


--
-- TOC entry 3761 (class 0 OID 16622)
-- Dependencies: 222
-- Data for Name: tenant_user; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.tenant_user (tenant_id, user_id, created_at, updated_at, is_admin, is_device_admin, is_gateway_admin) FROM stdin;
3e00683f-4c83-4c14-b1e1-afe543221836	0bd2b7e7-d684-42d9-8192-51d88da073a9	2026-05-07 11:59:41.679769+00	2026-05-07 11:59:41.679769+00	t	t	t
\.


--
-- TOC entry 3759 (class 0 OID 16605)
-- Dependencies: 220
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public."user" (id, external_id, created_at, updated_at, is_admin, is_active, email, email_verified, password_hash, note) FROM stdin;
0bd2b7e7-d684-42d9-8192-51d88da073a9	\N	2026-05-01 16:21:10.253969+00	2026-05-01 19:51:17.844022+00	t	t	adail101@hotmail.com	t	$pbkdf2-sha512$i=10000,l=32$76PaUrTF97tEoFyYtj8RUg$n6jMj5UHYDu9XdHXsvNSerK2S8C5H5vq/txk/Ojm328	AdailSilva-IoT
\.


--
-- TOC entry 3507 (class 2606 OID 16604)
-- Name: __diesel_schema_migrations __diesel_schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.__diesel_schema_migrations
    ADD CONSTRAINT __diesel_schema_migrations_pkey PRIMARY KEY (version);


--
-- TOC entry 3533 (class 2606 OID 16684)
-- Name: api_key api_key_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.api_key
    ADD CONSTRAINT api_key_pkey PRIMARY KEY (id);


--
-- TOC entry 3531 (class 2606 OID 16674)
-- Name: application_integration application_integration_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.application_integration
    ADD CONSTRAINT application_integration_pkey PRIMARY KEY (application_id, kind);


--
-- TOC entry 3526 (class 2606 OID 16660)
-- Name: application application_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.application
    ADD CONSTRAINT application_pkey PRIMARY KEY (id);


--
-- TOC entry 3551 (class 2606 OID 16735)
-- Name: device_keys device_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_keys
    ADD CONSTRAINT device_keys_pkey PRIMARY KEY (dev_eui);


--
-- TOC entry 3541 (class 2606 OID 16712)
-- Name: device device_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_pkey PRIMARY KEY (dev_eui);


--
-- TOC entry 3536 (class 2606 OID 16697)
-- Name: device_profile device_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_profile
    ADD CONSTRAINT device_profile_pkey PRIMARY KEY (id);


--
-- TOC entry 3568 (class 2606 OID 16814)
-- Name: device_profile_template device_profile_template_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_profile_template
    ADD CONSTRAINT device_profile_template_pkey PRIMARY KEY (id);


--
-- TOC entry 3553 (class 2606 OID 16747)
-- Name: device_queue_item device_queue_item_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_queue_item
    ADD CONSTRAINT device_queue_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3578 (class 2606 OID 16947)
-- Name: fuota_deployment_device fuota_deployment_device_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_device
    ADD CONSTRAINT fuota_deployment_device_pkey PRIMARY KEY (fuota_deployment_id, dev_eui);


--
-- TOC entry 3580 (class 2606 OID 16964)
-- Name: fuota_deployment_gateway fuota_deployment_gateway_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_gateway
    ADD CONSTRAINT fuota_deployment_gateway_pkey PRIMARY KEY (fuota_deployment_id, gateway_id);


--
-- TOC entry 3582 (class 2606 OID 16981)
-- Name: fuota_deployment_job fuota_deployment_job_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_job
    ADD CONSTRAINT fuota_deployment_job_pkey PRIMARY KEY (fuota_deployment_id, job);


--
-- TOC entry 3576 (class 2606 OID 16930)
-- Name: fuota_deployment fuota_deployment_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment
    ADD CONSTRAINT fuota_deployment_pkey PRIMARY KEY (id);


--
-- TOC entry 3520 (class 2606 OID 16644)
-- Name: gateway gateway_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_pkey PRIMARY KEY (gateway_id);


--
-- TOC entry 3562 (class 2606 OID 16776)
-- Name: multicast_group_device multicast_group_device_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_device
    ADD CONSTRAINT multicast_group_device_pkey PRIMARY KEY (multicast_group_id, dev_eui);


--
-- TOC entry 3570 (class 2606 OID 16835)
-- Name: multicast_group_gateway multicast_group_gateway_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_gateway
    ADD CONSTRAINT multicast_group_gateway_pkey PRIMARY KEY (multicast_group_id, gateway_id);


--
-- TOC entry 3560 (class 2606 OID 16762)
-- Name: multicast_group multicast_group_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group
    ADD CONSTRAINT multicast_group_pkey PRIMARY KEY (id);


--
-- TOC entry 3566 (class 2606 OID 16793)
-- Name: multicast_group_queue_item multicast_group_queue_item_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_queue_item
    ADD CONSTRAINT multicast_group_queue_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3572 (class 2606 OID 16876)
-- Name: relay_device relay_device_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.relay_device
    ADD CONSTRAINT relay_device_pkey PRIMARY KEY (relay_dev_eui, dev_eui);


--
-- TOC entry 3574 (class 2606 OID 16911)
-- Name: relay_gateway relay_gateway_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.relay_gateway
    ADD CONSTRAINT relay_gateway_pkey PRIMARY KEY (tenant_id, relay_id);


--
-- TOC entry 3515 (class 2606 OID 16620)
-- Name: tenant tenant_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.tenant
    ADD CONSTRAINT tenant_pkey PRIMARY KEY (id);


--
-- TOC entry 3518 (class 2606 OID 16626)
-- Name: tenant_user tenant_user_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.tenant_user
    ADD CONSTRAINT tenant_user_pkey PRIMARY KEY (tenant_id, user_id);


--
-- TOC entry 3511 (class 2606 OID 16611)
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- TOC entry 3534 (class 1259 OID 16690)
-- Name: idx_api_key_tenant_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_api_key_tenant_id ON public.api_key USING btree (tenant_id);


--
-- TOC entry 3527 (class 1259 OID 16667)
-- Name: idx_application_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_application_name_trgm ON public.application USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3528 (class 1259 OID 16892)
-- Name: idx_application_tags; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_application_tags ON public.application USING gin (tags);


--
-- TOC entry 3529 (class 1259 OID 16666)
-- Name: idx_application_tenant_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_application_tenant_id ON public.application USING btree (tenant_id);


--
-- TOC entry 3542 (class 1259 OID 16723)
-- Name: idx_device_application_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_application_id ON public.device USING btree (application_id);


--
-- TOC entry 3543 (class 1259 OID 16894)
-- Name: idx_device_dev_addr; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_dev_addr ON public.device USING btree (dev_addr);


--
-- TOC entry 3544 (class 1259 OID 16727)
-- Name: idx_device_dev_addr_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_dev_addr_trgm ON public.device USING gin (encode(dev_addr, 'hex'::text) public.gin_trgm_ops);


--
-- TOC entry 3545 (class 1259 OID 16726)
-- Name: idx_device_dev_eui_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_dev_eui_trgm ON public.device USING gin (encode(dev_eui, 'hex'::text) public.gin_trgm_ops);


--
-- TOC entry 3546 (class 1259 OID 16724)
-- Name: idx_device_device_profile_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_device_profile_id ON public.device USING btree (device_profile_id);


--
-- TOC entry 3547 (class 1259 OID 16725)
-- Name: idx_device_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_name_trgm ON public.device USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3537 (class 1259 OID 16704)
-- Name: idx_device_profile_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_name_trgm ON public.device_profile USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3538 (class 1259 OID 16705)
-- Name: idx_device_profile_tags; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_tags ON public.device_profile USING gin (tags);


--
-- TOC entry 3539 (class 1259 OID 16703)
-- Name: idx_device_profile_tenant_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_tenant_id ON public.device_profile USING btree (tenant_id);


--
-- TOC entry 3554 (class 1259 OID 16754)
-- Name: idx_device_queue_item_created_at; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_queue_item_created_at ON public.device_queue_item USING btree (created_at);


--
-- TOC entry 3555 (class 1259 OID 16753)
-- Name: idx_device_queue_item_dev_eui; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_queue_item_dev_eui ON public.device_queue_item USING btree (dev_eui);


--
-- TOC entry 3556 (class 1259 OID 16755)
-- Name: idx_device_queue_item_timeout_after; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_queue_item_timeout_after ON public.device_queue_item USING btree (timeout_after);


--
-- TOC entry 3548 (class 1259 OID 16895)
-- Name: idx_device_secondary_dev_addr; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_secondary_dev_addr ON public.device USING btree (secondary_dev_addr);


--
-- TOC entry 3549 (class 1259 OID 16728)
-- Name: idx_device_tags; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_tags ON public.device USING gin (tags);


--
-- TOC entry 3583 (class 1259 OID 16987)
-- Name: idx_fuota_deployment_job_completed_at; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_fuota_deployment_job_completed_at ON public.fuota_deployment_job USING btree (completed_at);


--
-- TOC entry 3584 (class 1259 OID 16988)
-- Name: idx_fuota_deployment_job_scheduler_run_after; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_fuota_deployment_job_scheduler_run_after ON public.fuota_deployment_job USING btree (scheduler_run_after);


--
-- TOC entry 3521 (class 1259 OID 16652)
-- Name: idx_gateway_id_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_gateway_id_trgm ON public.gateway USING gin (encode(gateway_id, 'hex'::text) public.gin_trgm_ops);


--
-- TOC entry 3522 (class 1259 OID 16651)
-- Name: idx_gateway_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_gateway_name_trgm ON public.gateway USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3523 (class 1259 OID 16653)
-- Name: idx_gateway_tags; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_gateway_tags ON public.gateway USING gin (tags);


--
-- TOC entry 3524 (class 1259 OID 16650)
-- Name: idx_gateway_tenant_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_gateway_tenant_id ON public.gateway USING btree (tenant_id);


--
-- TOC entry 3557 (class 1259 OID 16768)
-- Name: idx_multicast_group_application_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_multicast_group_application_id ON public.multicast_group USING btree (application_id);


--
-- TOC entry 3558 (class 1259 OID 16769)
-- Name: idx_multicast_group_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_multicast_group_name_trgm ON public.multicast_group USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3563 (class 1259 OID 16804)
-- Name: idx_multicast_group_queue_item_multicast_group_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_multicast_group_queue_item_multicast_group_id ON public.multicast_group_queue_item USING btree (multicast_group_id);


--
-- TOC entry 3564 (class 1259 OID 16805)
-- Name: idx_multicast_group_queue_item_scheduler_run_after; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_multicast_group_queue_item_scheduler_run_after ON public.multicast_group_queue_item USING btree (scheduler_run_after);


--
-- TOC entry 3512 (class 1259 OID 16621)
-- Name: idx_tenant_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_tenant_name_trgm ON public.tenant USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3513 (class 1259 OID 16890)
-- Name: idx_tenant_tags; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_tenant_tags ON public.tenant USING gin (tags);


--
-- TOC entry 3516 (class 1259 OID 16637)
-- Name: idx_tenant_user_user_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_tenant_user_user_id ON public.tenant_user USING btree (user_id);


--
-- TOC entry 3508 (class 1259 OID 16612)
-- Name: idx_user_email; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE UNIQUE INDEX idx_user_email ON public."user" USING btree (email);


--
-- TOC entry 3509 (class 1259 OID 16613)
-- Name: idx_user_external_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE UNIQUE INDEX idx_user_external_id ON public."user" USING btree (external_id);


--
-- TOC entry 3590 (class 2606 OID 16685)
-- Name: api_key api_key_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.api_key
    ADD CONSTRAINT api_key_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id) ON DELETE CASCADE;


--
-- TOC entry 3589 (class 2606 OID 16675)
-- Name: application_integration application_integration_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.application_integration
    ADD CONSTRAINT application_integration_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.application(id) ON DELETE CASCADE;


--
-- TOC entry 3588 (class 2606 OID 16661)
-- Name: application application_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.application
    ADD CONSTRAINT application_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id) ON DELETE CASCADE;


--
-- TOC entry 3592 (class 2606 OID 16713)
-- Name: device device_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.application(id) ON DELETE CASCADE;


--
-- TOC entry 3593 (class 2606 OID 16718)
-- Name: device device_device_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_device_profile_id_fkey FOREIGN KEY (device_profile_id) REFERENCES public.device_profile(id) ON DELETE CASCADE;


--
-- TOC entry 3594 (class 2606 OID 16736)
-- Name: device_keys device_keys_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_keys
    ADD CONSTRAINT device_keys_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3591 (class 2606 OID 16698)
-- Name: device_profile device_profile_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_profile
    ADD CONSTRAINT device_profile_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id) ON DELETE CASCADE;


--
-- TOC entry 3595 (class 2606 OID 16748)
-- Name: device_queue_item device_queue_item_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_queue_item
    ADD CONSTRAINT device_queue_item_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3606 (class 2606 OID 16931)
-- Name: fuota_deployment fuota_deployment_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment
    ADD CONSTRAINT fuota_deployment_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.application(id) ON DELETE CASCADE;


--
-- TOC entry 3608 (class 2606 OID 16953)
-- Name: fuota_deployment_device fuota_deployment_device_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_device
    ADD CONSTRAINT fuota_deployment_device_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3609 (class 2606 OID 16948)
-- Name: fuota_deployment_device fuota_deployment_device_fuota_deployment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_device
    ADD CONSTRAINT fuota_deployment_device_fuota_deployment_id_fkey FOREIGN KEY (fuota_deployment_id) REFERENCES public.fuota_deployment(id) ON DELETE CASCADE;


--
-- TOC entry 3607 (class 2606 OID 16936)
-- Name: fuota_deployment fuota_deployment_device_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment
    ADD CONSTRAINT fuota_deployment_device_profile_id_fkey FOREIGN KEY (device_profile_id) REFERENCES public.device_profile(id) ON DELETE CASCADE;


--
-- TOC entry 3610 (class 2606 OID 16965)
-- Name: fuota_deployment_gateway fuota_deployment_gateway_fuota_deployment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_gateway
    ADD CONSTRAINT fuota_deployment_gateway_fuota_deployment_id_fkey FOREIGN KEY (fuota_deployment_id) REFERENCES public.fuota_deployment(id) ON DELETE CASCADE;


--
-- TOC entry 3611 (class 2606 OID 16970)
-- Name: fuota_deployment_gateway fuota_deployment_gateway_gateway_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_gateway
    ADD CONSTRAINT fuota_deployment_gateway_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES public.gateway(gateway_id) ON DELETE CASCADE;


--
-- TOC entry 3612 (class 2606 OID 16982)
-- Name: fuota_deployment_job fuota_deployment_job_fuota_deployment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_job
    ADD CONSTRAINT fuota_deployment_job_fuota_deployment_id_fkey FOREIGN KEY (fuota_deployment_id) REFERENCES public.fuota_deployment(id) ON DELETE CASCADE;


--
-- TOC entry 3587 (class 2606 OID 16645)
-- Name: gateway gateway_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id) ON DELETE CASCADE;


--
-- TOC entry 3596 (class 2606 OID 16763)
-- Name: multicast_group multicast_group_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group
    ADD CONSTRAINT multicast_group_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.application(id) ON DELETE CASCADE;


--
-- TOC entry 3597 (class 2606 OID 16782)
-- Name: multicast_group_device multicast_group_device_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_device
    ADD CONSTRAINT multicast_group_device_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3598 (class 2606 OID 16777)
-- Name: multicast_group_device multicast_group_device_multicast_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_device
    ADD CONSTRAINT multicast_group_device_multicast_group_id_fkey FOREIGN KEY (multicast_group_id) REFERENCES public.multicast_group(id) ON DELETE CASCADE;


--
-- TOC entry 3601 (class 2606 OID 16841)
-- Name: multicast_group_gateway multicast_group_gateway_gateway_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_gateway
    ADD CONSTRAINT multicast_group_gateway_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES public.gateway(gateway_id) ON DELETE CASCADE;


--
-- TOC entry 3602 (class 2606 OID 16836)
-- Name: multicast_group_gateway multicast_group_gateway_multicast_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_gateway
    ADD CONSTRAINT multicast_group_gateway_multicast_group_id_fkey FOREIGN KEY (multicast_group_id) REFERENCES public.multicast_group(id) ON DELETE CASCADE;


--
-- TOC entry 3599 (class 2606 OID 16799)
-- Name: multicast_group_queue_item multicast_group_queue_item_gateway_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_queue_item
    ADD CONSTRAINT multicast_group_queue_item_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES public.gateway(gateway_id) ON DELETE CASCADE;


--
-- TOC entry 3600 (class 2606 OID 16794)
-- Name: multicast_group_queue_item multicast_group_queue_item_multicast_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_queue_item
    ADD CONSTRAINT multicast_group_queue_item_multicast_group_id_fkey FOREIGN KEY (multicast_group_id) REFERENCES public.multicast_group(id) ON DELETE CASCADE;


--
-- TOC entry 3603 (class 2606 OID 16882)
-- Name: relay_device relay_device_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.relay_device
    ADD CONSTRAINT relay_device_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3604 (class 2606 OID 16877)
-- Name: relay_device relay_device_relay_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.relay_device
    ADD CONSTRAINT relay_device_relay_dev_eui_fkey FOREIGN KEY (relay_dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3605 (class 2606 OID 16912)
-- Name: relay_gateway relay_gateway_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.relay_gateway
    ADD CONSTRAINT relay_gateway_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id) ON DELETE CASCADE;


--
-- TOC entry 3585 (class 2606 OID 16627)
-- Name: tenant_user tenant_user_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.tenant_user
    ADD CONSTRAINT tenant_user_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id) ON DELETE CASCADE;


--
-- TOC entry 3586 (class 2606 OID 16632)
-- Name: tenant_user tenant_user_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.tenant_user
    ADD CONSTRAINT tenant_user_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


-- Completed on 2026-05-18 18:39:20 -03

--
-- PostgreSQL database dump complete
--

\unrestrict j5cNAd0xWLvEJNqn3cY5lIwrsHTfbx8EjByeev3F7rOcFfeoRN3VbF97M8xPbgW

