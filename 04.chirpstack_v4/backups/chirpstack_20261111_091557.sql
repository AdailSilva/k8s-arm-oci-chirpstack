--
-- PostgreSQL database dump
--

\restrict d5RccxLFRtL7Q9xbeuwbUEQF1cWdR72phd17X9j0Cb4rNA4Pl0sHEo0QH5uIlZY

-- Dumped from database version 17.5 (Debian 17.5-1.pgdg130+1)
-- Dumped by pg_dump version 17.11 (Ubuntu 17.11-1.pgdg24.04+2)

-- Started on 2026-11-11 09:16:08 -03

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
-- TOC entry 3808 (class 1262 OID 17239)
-- Name: chirpstack; Type: DATABASE; Schema: -; Owner: chirpstack
--

CREATE DATABASE chirpstack WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE chirpstack OWNER TO chirpstack;

\unrestrict d5RccxLFRtL7Q9xbeuwbUEQF1cWdR72phd17X9j0Cb4rNA4Pl0sHEo0QH5uIlZY
\connect chirpstack
\restrict d5RccxLFRtL7Q9xbeuwbUEQF1cWdR72phd17X9j0Cb4rNA4Pl0sHEo0QH5uIlZY

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
-- TOC entry 3 (class 3079 OID 17321)
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- TOC entry 3809 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- TOC entry 2 (class 3079 OID 17240)
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- TOC entry 3810 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 219 (class 1259 OID 17449)
-- Name: __diesel_schema_migrations; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.__diesel_schema_migrations (
    version character varying(50) NOT NULL,
    run_on timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.__diesel_schema_migrations OWNER TO chirpstack;

--
-- TOC entry 220 (class 1259 OID 17453)
-- Name: api_key; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.api_key (
    id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    is_admin boolean NOT NULL,
    tenant_id uuid,
    is_read_only boolean NOT NULL
);


ALTER TABLE public.api_key OWNER TO chirpstack;

--
-- TOC entry 221 (class 1259 OID 17456)
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
-- TOC entry 222 (class 1259 OID 17461)
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
-- TOC entry 223 (class 1259 OID 17466)
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
-- TOC entry 224 (class 1259 OID 17471)
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
-- TOC entry 225 (class 1259 OID 17476)
-- Name: device_profile; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.device_profile (
    id uuid NOT NULL,
    tenant_id uuid,
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
    app_layer_params jsonb NOT NULL,
    device_id uuid,
    firmware_version character varying(20) NOT NULL,
    vendor_profile_id integer NOT NULL,
    supported_uplink_data_rates smallint[] NOT NULL
);


ALTER TABLE public.device_profile OWNER TO chirpstack;

--
-- TOC entry 243 (class 1259 OID 17789)
-- Name: device_profile_device; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.device_profile_device (
    id uuid NOT NULL,
    vendor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    description text NOT NULL,
    metadata jsonb NOT NULL
);


ALTER TABLE public.device_profile_device OWNER TO chirpstack;

--
-- TOC entry 226 (class 1259 OID 17481)
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
-- TOC entry 242 (class 1259 OID 17779)
-- Name: device_profile_vendor; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.device_profile_vendor (
    id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name text NOT NULL,
    vendor_id integer NOT NULL,
    ouis text[] NOT NULL,
    metadata jsonb NOT NULL
);


ALTER TABLE public.device_profile_vendor OWNER TO chirpstack;

--
-- TOC entry 227 (class 1259 OID 17486)
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
-- TOC entry 228 (class 1259 OID 17491)
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
-- TOC entry 229 (class 1259 OID 17496)
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
-- TOC entry 230 (class 1259 OID 17501)
-- Name: fuota_deployment_gateway; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.fuota_deployment_gateway (
    fuota_deployment_id uuid NOT NULL,
    gateway_id bytea NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.fuota_deployment_gateway OWNER TO chirpstack;

--
-- TOC entry 231 (class 1259 OID 17506)
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
-- TOC entry 232 (class 1259 OID 17511)
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
    properties jsonb NOT NULL,
    downlink_priority smallint NOT NULL
);


ALTER TABLE public.gateway OWNER TO chirpstack;

--
-- TOC entry 233 (class 1259 OID 17516)
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
-- TOC entry 234 (class 1259 OID 17521)
-- Name: multicast_group_device; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.multicast_group_device (
    multicast_group_id uuid NOT NULL,
    dev_eui bytea NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.multicast_group_device OWNER TO chirpstack;

--
-- TOC entry 235 (class 1259 OID 17526)
-- Name: multicast_group_gateway; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.multicast_group_gateway (
    multicast_group_id uuid NOT NULL,
    gateway_id bytea NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.multicast_group_gateway OWNER TO chirpstack;

--
-- TOC entry 236 (class 1259 OID 17531)
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
-- TOC entry 237 (class 1259 OID 17536)
-- Name: relay_device; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.relay_device (
    relay_dev_eui bytea NOT NULL,
    dev_eui bytea NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.relay_device OWNER TO chirpstack;

--
-- TOC entry 238 (class 1259 OID 17541)
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
-- TOC entry 239 (class 1259 OID 17546)
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
    tags jsonb NOT NULL,
    dev_addr_prefixes text[] NOT NULL
);


ALTER TABLE public.tenant OWNER TO chirpstack;

--
-- TOC entry 240 (class 1259 OID 17551)
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
-- TOC entry 241 (class 1259 OID 17554)
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
-- TOC entry 3778 (class 0 OID 17449)
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
202511111404590000	2026-11-09 19:53:35.007117
202512101058490000	2026-11-09 19:53:35.100365
202602181001240000	2026-11-09 19:53:35.103137
202605201051510000	2026-11-09 19:53:35.105528
202606150939590000	2026-11-09 19:53:35.107943
\.


--
-- TOC entry 3779 (class 0 OID 17453)
-- Dependencies: 220
-- Data for Name: api_key; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.api_key (id, created_at, name, is_admin, tenant_id, is_read_only) FROM stdin;
\.


--
-- TOC entry 3780 (class 0 OID 17456)
-- Dependencies: 221
-- Data for Name: application; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.application (id, tenant_id, created_at, updated_at, name, description, mqtt_tls_cert, tags) FROM stdin;
56560a65-2fb8-444c-a1ee-bd0ee4be0946	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-04 02:04:59.496447+00	2026-05-04 02:04:59.496447+00	devices_au915	Frequency Plan AU915	\N	{}
\.


--
-- TOC entry 3781 (class 0 OID 17461)
-- Dependencies: 222
-- Data for Name: application_integration; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.application_integration (application_id, kind, created_at, updated_at, configuration) FROM stdin;
\.


--
-- TOC entry 3782 (class 0 OID 17466)
-- Dependencies: 223
-- Data for Name: device; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device (dev_eui, application_id, device_profile_id, created_at, updated_at, last_seen_at, scheduler_run_after, name, description, external_power_source, battery_level, margin, dr, latitude, longitude, altitude, dev_addr, enabled_class, skip_fcnt_check, is_disabled, tags, variables, join_eui, secondary_dev_addr, device_session, app_layer_params, f_cnt_up) FROM stdin;
\\x08fdbe4bc604e8f8	56560a65-2fb8-444c-a1ee-bd0ee4be0946	1bbfac1d-4e6f-44b4-8e48-aae6dcf6c591	2026-05-10 13:53:34.770399+00	2026-05-11 21:06:02.986362+00	2026-11-09 21:23:49.892568+00	2026-11-09 21:23:54.88075+00	ESP32 RF95W (ABP)	ESP32 with RF95W (ABP)	f	\N	5	5	\N	\N	\N	\\x00aa88ca	A	t	f	{}	{}	\\x0000000000000000	\N	\\x120400aa88ca20032a10151f7779d7aaee422a74568380db70453210151f7779d7aaee422a74568380db70453a10151f7779d7aaee422a74568380db704542121210fd91d55dce3af1023093e289a1d9f3df5002680170018001088801a0e1a1b80392010908090a0b0c0d0e0f41b80101c80105f20114080115cdcc0c41200128fbffffffffffffffff01f2011408021500001041200128faffffffffffffffff01f2011408031500001041200128faffffffffffffffff01f2011408041533332341200128f7ffffffffffffffff01f2011408051500000041200128faffffffffffffffff01f2011408061500000841200128faffffffffffffffff01f20114080715cdcc0c41200128faffffffffffffffff01f2011408081533331341200128f9ffffffffffffffff01f2011408091533332341200128f7ffffffffffffffff01f20114080a1533331341200128f9ffffffffffffffff01f20114080b1500001841200128f9ffffffffffffffff01f20114080c1500000841200128faffffffffffffffff01f20114080d1500000841200128faffffffffffffffff01f20114080e1500002041200128f9ffffffffffffffff01f20114080f1500001841200128f7ffffffffffffffff01f2011408101500001841200128f9ffffffffffffffff01f201140811150000e040200128faffffffffffffffff01f2011408121533331341200128f9ffffffffffffffff01f2011408131500002041200128f9ffffffffffffffff01f2011408141500001841200128f7ffffffffffffffff0182020c0882f2c8d70610a4b5b6ec01c2020761753931355f31e20238080512340a08a842e3fffe90a3d410f7ffffffffffffffff011d000018413204158672934a103e00683f4c834c14b1e1afe543221836500a	{"ts004_session_cnt": [0, 0, 0, 0]}	21
\\x5f904b22e1ce458c	56560a65-2fb8-444c-a1ee-bd0ee4be0946	1bbfac1d-4e6f-44b4-8e48-aae6dcf6c591	2026-11-09 20:38:35.980226+00	2026-11-10 15:14:38.350418+00	2026-11-09 22:03:20.866133+00	2026-11-09 22:03:25.853621+00	Radioenge EndDevice (STM32L071) - ABP	Radioenge LoRaWAN EndDevice - STM32L071CZT6 - AU915 - ABP	f	\N	\N	5	\N	\N	\N	\\x00d382ec	C	f	f	{}	{}	\\x0000000000000000	\N	\\x120400d382ec20032a107277c9aed02a1dac8d9197f07c64544632107277c9aed02a1dac8d9197f07c6454463a107277c9aed02a1dac8d9197f07c64544642121210677c441968c784f6f67be569d9320b70500270018001088801a0e1a1b803920148000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f4041424344454647b80101c80105f201140842150000e040200128f7ffffffffffffffff01f2011408431533331341200128f7ffffffffffffffff01f2011408441500002041200128f5ffffffffffffffff01f2011408451500001841200128f9ffffffffffffffff01f2011408461533331341200128faffffffffffffffff01f2011408471500001841200128f9ffffffffffffffff01f2011408481500001041200128faffffffffffffffff01f2011408491500002041200128faffffffffffffffff01f20114084a1533331341200128faffffffffffffffff01f20114084b15cdcc0c41200128fbffffffffffffffff01f20114084c1533331341200128ffffffffffffffffff01f20114084d1533331341200128faffffffffffffffff01f20114084e15cdcc1c41200128f9ffffffffffffffff01f20114084f156666c640200128f5ffffffffffffffff01f2011408501500001041200128faffffffffffffffff01f20114085115cdcc1c41200128fbffffffffffffffff01f2011408521533331341200128faffffffffffffffff01f2011408531500002041200128faffffffffffffffff01f201140854159a99f940200128f9ffffffffffffffff01f20114085515cdcc1c41200128f5ffffffffffffffff01fa01040803100282020b08d781c9d70610ccc7ec07c2020761753931355f31da02050806120106e20238080512340a08a842e3fffe90a3d410f5ffffffffffffffff011dcdcc1c41320428311b0c4a103e00683f4c834c14b1e1afe543221836500a	{"ts004_session_cnt": [0, 0, 0, 0]}	86
\\x0379385c33313636	56560a65-2fb8-444c-a1ee-bd0ee4be0946	cff3ab28-afa3-4909-8958-e01ab4984a3b	2026-11-09 20:39:27.299081+00	2026-11-10 15:14:59.817992+00	2026-11-11 12:15:26.672048+00	2026-11-11 12:15:31.661114+00	Radioenge EndDevice (STM32L071) - OTAA	Radioenge LoRaWAN EndDevice - STM32L071CZT6 - AU915 - OTAA	t	\N	7	5	\N	\N	\N	\\x002a5b58	C	f	f	{}	{}	\\xb2f634a1e62c10c7	\N	\\x1204002a5b5820032a10afa376d59f961cc7d7bcb6a51d08f8ad3210afa376d59f961cc7d7bcb6a51d08f8ad3a10afa376d59f961cc7d7bcb6a51d08f8ad421212104a2ecbbe49a5015d11fea89069232d21500170018001088801a0e1a1b80392010908090a0b0c0d0e0f41b80101c80105f20114080115cdcc0c41200128ffffffffffffffffff01f20114080215cdcc1c41200128f7ffffffffffffffff01f2011408031500000041200128ffffffffffffffffff01f201090804150000f0402001f2011408061500002041200128edffffffffffffffff01f20114080715cdcc1c41200128e5ffffffffffffffff01f201140808150000e040200128ffffffffffffffffff01f2011408091500001841200128ffffffffffffffffff0182020c08b5b5d1d70610ec99ded301c2020761753931355f31da02050806120106e20238080512340a08a842e3fffe90a3d410ffffffffffffffffff011d0000184132041d0fa3834a103e00683f4c834c14b1e1afe543221836500a	{"ts004_session_cnt": [0, 0, 0, 0]}	10
\\xf38df5e5a31e63de	56560a65-2fb8-444c-a1ee-bd0ee4be0946	cff3ab28-afa3-4909-8958-e01ab4984a3b	2026-05-04 02:06:34.517515+00	2026-05-10 15:19:01.527258+00	2026-11-11 12:16:01.465863+00	2026-11-11 12:16:06.457286+00	ESP32 RF95W (OTAA)	ESP32 with RF95W (OTAA)	f	\N	7	5	\N	\N	\N	\\x00755580	C	f	f	{}	{}	\\xc7102ce6a134f6b2	\N	\\x12040075558020032a10645998acf169ecbcd9d4bd3dabb448663210645998acf169ecbcd9d4bd3dabb448663a10645998acf169ecbcd9d4bd3dabb4486642121210d1c4390d7e9b4ec4c07de2022416fc39500170018001088801a0e1a1b80392010908090a0b0c0d0e0f41b80101c80105f2011408171500001841200128f9ffffffffffffffff01f20114081815cdcc0c41200128faffffffffffffffff01f20114081915cdcc1c41200128f6ffffffffffffffff01f20114081a1500001041200128f9ffffffffffffffff01f20114081b1500001041200128f7ffffffffffffffff01f20114081c156666e640200128faffffffffffffffff01f20114081d1533332341200128f5ffffffffffffffff01f20114081e159a99f940200128f7ffffffffffffffff01f20114081f1500002041200128f9ffffffffffffffff01f2011408201533331341200128f7ffffffffffffffff01f20114082115cdcc2c41200128f7ffffffffffffffff01f2011408231533332341200128f7ffffffffffffffff01f20114082415cdcc1c41200128f7ffffffffffffffff01f2011408251500000041200128f7ffffffffffffffff01f2011408261533330341200128f8ffffffffffffffff01f20114082715cdcc2c41200128f5ffffffffffffffff01f2011408281500001041200128f9ffffffffffffffff01f20114082915cdcc1c41200128f7ffffffffffffffff01f20114082a15cdcc0c41200128f9ffffffffffffffff01f20114082b150000e040200128f7ffffffffffffffff0182020c0881b5d1d70610eaa2c1ec01c2020761753931355f31e20238080512340a08a842e3fffe90a3d410f7ffffffffffffffff011d0000e04032041f1dff1b4a103e00683f4c834c14b1e1afe543221836500a	{"ts004_session_cnt": [0, 0, 0, 0]}	44
\.


--
-- TOC entry 3783 (class 0 OID 17471)
-- Dependencies: 224
-- Data for Name: device_keys; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device_keys (dev_eui, created_at, updated_at, nwk_key, app_key, dev_nonces, join_nonce, gen_app_key) FROM stdin;
\\x0379385c33313636	2026-11-09 20:39:38.292511+00	2026-11-11 12:08:15.858644+00	\\x6fc57c4cda46ddc502bcb7855e4e94ae	\\x00000000000000000000000000000000	{"b2f634a1e62c10c7": [16, 1, 2, 3, 5, 7, 4, 6, 9, 10, 8, 72, 73, 74]}	14	\\x6fc57c4cda46ddc502bcb7855e4e94ae
\\xf38df5e5a31e63de	2026-05-04 02:06:50.902336+00	2026-11-11 12:07:24.562686+00	\\x6fc57c4cda46ddc502bcb7855e4e94ae	\\x00000000000000000000000000000000	{"c7102ce6a134f6b2": [39887, 32611, 9324, 51147, 27064, 9067, 2140, 3264, 2337, 35373, 2760, 522, 42945, 16868, 4147, 26038, 39257, 13414, 26958, 12550, 19365, 56516, 53749, 29433, 27104, 46854, 11035, 22905, 55745, 55489, 51674, 48135, 23659, 26471, 38952, 10916, 59466, 21142, 35911, 5254, 14405, 15793, 51203, 11815, 41815, 3520, 18663, 41650, 47894, 50588, 24383, 5622, 9717, 1272, 20703, 49800, 15851, 45942, 63845, 41080, 40483, 12185, 13121, 45355, 24047, 59808, 33980, 26241, 51163, 54092, 28870, 49331, 25240, 25241, 25242, 10388, 63653, 47218, 39705, 55002, 46809, 28542, 34686, 1622, 33727]}	85	\\x00000000000000000000000000000000
\.


--
-- TOC entry 3784 (class 0 OID 17476)
-- Dependencies: 225
-- Data for Name: device_profile; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device_profile (id, tenant_id, created_at, updated_at, name, region, mac_version, reg_params_revision, adr_algorithm_id, payload_codec_runtime, uplink_interval, device_status_req_interval, supports_otaa, supports_class_b, supports_class_c, tags, payload_codec_script, flush_queue_on_activate, description, measurements, auto_detect_measurements, region_config_id, allow_roaming, rx1_delay, abp_params, class_b_params, class_c_params, relay_params, app_layer_params, device_id, firmware_version, vendor_profile_id, supported_uplink_data_rates) FROM stdin;
6d427ef3-0285-40b6-97ee-419cd1454da6	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-10 14:33:18.153052+00	2026-11-09 21:40:29.472494+00	Devide Profile - AU915_0 - 1.0.3 - A (OTAA)	AU915	1.0.3	A	default	JS	3600	1	t	f	t	{}	/**\n * Codec ChirpStack v4 — payload ASCII\n *\n * Uplink : bytes -> { text, length, hex, fPort }\n *   ex.: "QWRhaWxTaWx2YS1Jb1Q=" -> { "text": "AdailSilva-IoT", ... }\n * Downlink: { "text": "LED ON" } -> bytes ASCII\n */\n\nfunction decodeUplink(input) {\n  var bytes = input.bytes || [];\n  var warnings = [];\n\n  if (bytes.length === 0) {\n    return { errors: ["payload vazio"] };\n  }\n\n  var text = "";\n  var hex = [];\n  var nonPrintable = 0;\n\n  for (var i = 0; i < bytes.length; i++) {\n    var b = bytes[i] & 0xff;\n    hex.push((b < 16 ? "0" : "") + b.toString(16));\n\n    if (b >= 0x20 && b <= 0x7e) {\n      text += String.fromCharCode(b);          // ASCII imprimível\n    } else if (b === 0x0a || b === 0x0d || b === 0x09) {\n      text += String.fromCharCode(b);          // \\n \\r \\t\n    } else if (b === 0x00 && i === bytes.length - 1) {\n      // '\\0' final (string C): ignora\n    } else {\n      text += "?";\n      nonPrintable++;\n    }\n  }\n\n  if (nonPrintable > 0) {\n    warnings.push(nonPrintable + " byte(s) fora do ASCII imprimível substituído(s) por '?'");\n  }\n\n  return {\n    data: {\n      text: text,\n      length: bytes.length,\n      hex: hex.join(""),\n      fPort: input.fPort\n    },\n    warnings: warnings\n  };\n}\n\nfunction encodeDownlink(input) {\n  var text = input.data && input.data.text;\n\n  if (typeof text !== "string" || text.length === 0) {\n    return { errors: ["informe o campo 'text' (string não vazia)"] };\n  }\n\n  var bytes = [];\n  for (var i = 0; i < text.length; i++) {\n    var c = text.charCodeAt(i);\n    if (c > 0x7e) {\n      return { errors: ["caractere não ASCII na posição " + i + ": '" + text.charAt(i) + "'"] };\n    }\n    bytes.push(c);\n  }\n\n  return { bytes: bytes };\n}\n	t	Devide Profile Region AU915 - Region configuration 0 - MAC version LoRaWAN 1.0.3 - Regional parameters revision A (OTAA)	{}	t	au915_0	f	0	\N	\N	{"timeout": 0}	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}	\N		0	{}
a82611dc-b236-422c-a1e5-87c155cfb3d7	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-10 14:33:45.174072+00	2026-11-09 21:41:22.301687+00	Devide Profile - AU915_1 - 1.0.3 - A (OTAA)	AU915	1.0.3	A	default	JS	3600	1	t	f	t	{}	/**\n * Codec ChirpStack v4 — payload ASCII\n *\n * Uplink : bytes -> { text, length, hex, fPort }\n *   ex.: "QWRhaWxTaWx2YS1Jb1Q=" -> { "text": "AdailSilva-IoT", ... }\n * Downlink: { "text": "LED ON" } -> bytes ASCII\n */\n\nfunction decodeUplink(input) {\n  var bytes = input.bytes || [];\n  var warnings = [];\n\n  if (bytes.length === 0) {\n    return { errors: ["payload vazio"] };\n  }\n\n  var text = "";\n  var hex = [];\n  var nonPrintable = 0;\n\n  for (var i = 0; i < bytes.length; i++) {\n    var b = bytes[i] & 0xff;\n    hex.push((b < 16 ? "0" : "") + b.toString(16));\n\n    if (b >= 0x20 && b <= 0x7e) {\n      text += String.fromCharCode(b);          // ASCII imprimível\n    } else if (b === 0x0a || b === 0x0d || b === 0x09) {\n      text += String.fromCharCode(b);          // \\n \\r \\t\n    } else if (b === 0x00 && i === bytes.length - 1) {\n      // '\\0' final (string C): ignora\n    } else {\n      text += "?";\n      nonPrintable++;\n    }\n  }\n\n  if (nonPrintable > 0) {\n    warnings.push(nonPrintable + " byte(s) fora do ASCII imprimível substituído(s) por '?'");\n  }\n\n  return {\n    data: {\n      text: text,\n      length: bytes.length,\n      hex: hex.join(""),\n      fPort: input.fPort\n    },\n    warnings: warnings\n  };\n}\n\nfunction encodeDownlink(input) {\n  var text = input.data && input.data.text;\n\n  if (typeof text !== "string" || text.length === 0) {\n    return { errors: ["informe o campo 'text' (string não vazia)"] };\n  }\n\n  var bytes = [];\n  for (var i = 0; i < text.length; i++) {\n    var c = text.charCodeAt(i);\n    if (c > 0x7e) {\n      return { errors: ["caractere não ASCII na posição " + i + ": '" + text.charAt(i) + "'"] };\n    }\n    bytes.push(c);\n  }\n\n  return { bytes: bytes };\n}\n	t	Devide Profile Region AU915 - Region configuration 1 - MAC version LoRaWAN 1.0.3 - Regional parameters revision A (OTAA)	{}	t	au915_1	f	0	\N	\N	{"timeout": 0}	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}	\N		0	{}
e630fede-3319-4974-931d-6bc00ee12c15	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:55:57.800665+00	2026-11-09 21:40:37.651872+00	Devide Profile - AU915_0 - 1.0.3 - B (ABP)	AU915	1.0.3	B	default	JS	3600	1	f	f	t	{}	/**\n * Codec ChirpStack v4 — payload ASCII\n *\n * Uplink : bytes -> { text, length, hex, fPort }\n *   ex.: "QWRhaWxTaWx2YS1Jb1Q=" -> { "text": "AdailSilva-IoT", ... }\n * Downlink: { "text": "LED ON" } -> bytes ASCII\n */\n\nfunction decodeUplink(input) {\n  var bytes = input.bytes || [];\n  var warnings = [];\n\n  if (bytes.length === 0) {\n    return { errors: ["payload vazio"] };\n  }\n\n  var text = "";\n  var hex = [];\n  var nonPrintable = 0;\n\n  for (var i = 0; i < bytes.length; i++) {\n    var b = bytes[i] & 0xff;\n    hex.push((b < 16 ? "0" : "") + b.toString(16));\n\n    if (b >= 0x20 && b <= 0x7e) {\n      text += String.fromCharCode(b);          // ASCII imprimível\n    } else if (b === 0x0a || b === 0x0d || b === 0x09) {\n      text += String.fromCharCode(b);          // \\n \\r \\t\n    } else if (b === 0x00 && i === bytes.length - 1) {\n      // '\\0' final (string C): ignora\n    } else {\n      text += "?";\n      nonPrintable++;\n    }\n  }\n\n  if (nonPrintable > 0) {\n    warnings.push(nonPrintable + " byte(s) fora do ASCII imprimível substituído(s) por '?'");\n  }\n\n  return {\n    data: {\n      text: text,\n      length: bytes.length,\n      hex: hex.join(""),\n      fPort: input.fPort\n    },\n    warnings: warnings\n  };\n}\n\nfunction encodeDownlink(input) {\n  var text = input.data && input.data.text;\n\n  if (typeof text !== "string" || text.length === 0) {\n    return { errors: ["informe o campo 'text' (string não vazia)"] };\n  }\n\n  var bytes = [];\n  for (var i = 0; i < text.length; i++) {\n    var c = text.charCodeAt(i);\n    if (c > 0x7e) {\n      return { errors: ["caractere não ASCII na posição " + i + ": '" + text.charAt(i) + "'"] };\n    }\n    bytes.push(c);\n  }\n\n  return { bytes: bytes };\n}\n	t	Devide Profile Region AU915 - Region configuration 0 - MAC version LoRaWAN 1.0.3 - Regional parameters revision B (ABP)	{}	t	au915_0	f	0	{"rx2_dr": 8, "rx2_freq": 923300000, "rx1_delay": 1, "rx1_dr_offset": 0}	\N	{"timeout": 0}	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}	\N		0	{}
1bbfac1d-4e6f-44b4-8e48-aae6dcf6c591	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:56:31.807982+00	2026-11-09 21:41:30.390954+00	Devide Profile - AU915_1 - 1.0.3 - B (ABP)	AU915	1.0.3	B	default	JS	3600	1	f	f	t	{}	/**\n * Codec ChirpStack v4 — payload ASCII\n *\n * Uplink : bytes -> { text, length, hex, fPort }\n *   ex.: "QWRhaWxTaWx2YS1Jb1Q=" -> { "text": "AdailSilva-IoT", ... }\n * Downlink: { "text": "LED ON" } -> bytes ASCII\n */\n\nfunction decodeUplink(input) {\n  var bytes = input.bytes || [];\n  var warnings = [];\n\n  if (bytes.length === 0) {\n    return { errors: ["payload vazio"] };\n  }\n\n  var text = "";\n  var hex = [];\n  var nonPrintable = 0;\n\n  for (var i = 0; i < bytes.length; i++) {\n    var b = bytes[i] & 0xff;\n    hex.push((b < 16 ? "0" : "") + b.toString(16));\n\n    if (b >= 0x20 && b <= 0x7e) {\n      text += String.fromCharCode(b);          // ASCII imprimível\n    } else if (b === 0x0a || b === 0x0d || b === 0x09) {\n      text += String.fromCharCode(b);          // \\n \\r \\t\n    } else if (b === 0x00 && i === bytes.length - 1) {\n      // '\\0' final (string C): ignora\n    } else {\n      text += "?";\n      nonPrintable++;\n    }\n  }\n\n  if (nonPrintable > 0) {\n    warnings.push(nonPrintable + " byte(s) fora do ASCII imprimível substituído(s) por '?'");\n  }\n\n  return {\n    data: {\n      text: text,\n      length: bytes.length,\n      hex: hex.join(""),\n      fPort: input.fPort\n    },\n    warnings: warnings\n  };\n}\n\nfunction encodeDownlink(input) {\n  var text = input.data && input.data.text;\n\n  if (typeof text !== "string" || text.length === 0) {\n    return { errors: ["informe o campo 'text' (string não vazia)"] };\n  }\n\n  var bytes = [];\n  for (var i = 0; i < text.length; i++) {\n    var c = text.charCodeAt(i);\n    if (c > 0x7e) {\n      return { errors: ["caractere não ASCII na posição " + i + ": '" + text.charAt(i) + "'"] };\n    }\n    bytes.push(c);\n  }\n\n  return { bytes: bytes };\n}\n	t	Devide Profile Region AU915 - Region configuration 1 - MAC version LoRaWAN 1.0.3 - Regional parameters revision B (ABP)	{"hex": {"kind": "UNKNOWN", "name": ""}, "text": {"kind": "UNKNOWN", "name": ""}, "fPort": {"kind": "UNKNOWN", "name": ""}, "length": {"kind": "UNKNOWN", "name": ""}}	t	au915_1	f	0	{"rx2_dr": 8, "rx2_freq": 923300000, "rx1_delay": 1, "rx1_dr_offset": 0}	\N	{"timeout": 0}	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}	\N		0	{}
b9f5f095-7bcc-427f-8381-b9dd8eba0e1a	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:54:50.69657+00	2026-11-09 21:40:21.960557+00	Devide Profile - AU915_0 - 1.0.3 - A (ABP)	AU915	1.0.3	A	default	JS	3600	1	f	f	t	{}	/**\n * Codec ChirpStack v4 — payload ASCII\n *\n * Uplink : bytes -> { text, length, hex, fPort }\n *   ex.: "QWRhaWxTaWx2YS1Jb1Q=" -> { "text": "AdailSilva-IoT", ... }\n * Downlink: { "text": "LED ON" } -> bytes ASCII\n */\n\nfunction decodeUplink(input) {\n  var bytes = input.bytes || [];\n  var warnings = [];\n\n  if (bytes.length === 0) {\n    return { errors: ["payload vazio"] };\n  }\n\n  var text = "";\n  var hex = [];\n  var nonPrintable = 0;\n\n  for (var i = 0; i < bytes.length; i++) {\n    var b = bytes[i] & 0xff;\n    hex.push((b < 16 ? "0" : "") + b.toString(16));\n\n    if (b >= 0x20 && b <= 0x7e) {\n      text += String.fromCharCode(b);          // ASCII imprimível\n    } else if (b === 0x0a || b === 0x0d || b === 0x09) {\n      text += String.fromCharCode(b);          // \\n \\r \\t\n    } else if (b === 0x00 && i === bytes.length - 1) {\n      // '\\0' final (string C): ignora\n    } else {\n      text += "?";\n      nonPrintable++;\n    }\n  }\n\n  if (nonPrintable > 0) {\n    warnings.push(nonPrintable + " byte(s) fora do ASCII imprimível substituído(s) por '?'");\n  }\n\n  return {\n    data: {\n      text: text,\n      length: bytes.length,\n      hex: hex.join(""),\n      fPort: input.fPort\n    },\n    warnings: warnings\n  };\n}\n\nfunction encodeDownlink(input) {\n  var text = input.data && input.data.text;\n\n  if (typeof text !== "string" || text.length === 0) {\n    return { errors: ["informe o campo 'text' (string não vazia)"] };\n  }\n\n  var bytes = [];\n  for (var i = 0; i < text.length; i++) {\n    var c = text.charCodeAt(i);\n    if (c > 0x7e) {\n      return { errors: ["caractere não ASCII na posição " + i + ": '" + text.charAt(i) + "'"] };\n    }\n    bytes.push(c);\n  }\n\n  return { bytes: bytes };\n}\n	t	Devide Profile Region AU915 - Region configuration 0 - MAC version LoRaWAN 1.0.3 - Regional parameters revision A (ABP)	{}	t	au915_0	f	0	{"rx2_dr": 8, "rx2_freq": 923300000, "rx1_delay": 1, "rx1_dr_offset": 0}	\N	{"timeout": 0}	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}	\N		0	{}
0cc8dba0-cbea-4784-b769-b0dcf0dab8ff	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-10 14:34:14.531822+00	2026-11-09 21:40:45.349499+00	Devide Profile - AU915_0 - 1.0.3 - B (OTAA)	AU915	1.0.3	B	default	JS	3600	1	t	f	t	{}	/**\n * Codec ChirpStack v4 — payload ASCII\n *\n * Uplink : bytes -> { text, length, hex, fPort }\n *   ex.: "QWRhaWxTaWx2YS1Jb1Q=" -> { "text": "AdailSilva-IoT", ... }\n * Downlink: { "text": "LED ON" } -> bytes ASCII\n */\n\nfunction decodeUplink(input) {\n  var bytes = input.bytes || [];\n  var warnings = [];\n\n  if (bytes.length === 0) {\n    return { errors: ["payload vazio"] };\n  }\n\n  var text = "";\n  var hex = [];\n  var nonPrintable = 0;\n\n  for (var i = 0; i < bytes.length; i++) {\n    var b = bytes[i] & 0xff;\n    hex.push((b < 16 ? "0" : "") + b.toString(16));\n\n    if (b >= 0x20 && b <= 0x7e) {\n      text += String.fromCharCode(b);          // ASCII imprimível\n    } else if (b === 0x0a || b === 0x0d || b === 0x09) {\n      text += String.fromCharCode(b);          // \\n \\r \\t\n    } else if (b === 0x00 && i === bytes.length - 1) {\n      // '\\0' final (string C): ignora\n    } else {\n      text += "?";\n      nonPrintable++;\n    }\n  }\n\n  if (nonPrintable > 0) {\n    warnings.push(nonPrintable + " byte(s) fora do ASCII imprimível substituído(s) por '?'");\n  }\n\n  return {\n    data: {\n      text: text,\n      length: bytes.length,\n      hex: hex.join(""),\n      fPort: input.fPort\n    },\n    warnings: warnings\n  };\n}\n\nfunction encodeDownlink(input) {\n  var text = input.data && input.data.text;\n\n  if (typeof text !== "string" || text.length === 0) {\n    return { errors: ["informe o campo 'text' (string não vazia)"] };\n  }\n\n  var bytes = [];\n  for (var i = 0; i < text.length; i++) {\n    var c = text.charCodeAt(i);\n    if (c > 0x7e) {\n      return { errors: ["caractere não ASCII na posição " + i + ": '" + text.charAt(i) + "'"] };\n    }\n    bytes.push(c);\n  }\n\n  return { bytes: bytes };\n}\n	t	Devide Profile Region AU915 - Region configuration 0 - MAC version LoRaWAN 1.0.3 - Regional parameters revision B (OTAA)	{}	t	au915_0	f	0	\N	\N	{"timeout": 0}	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}	\N		0	{}
f984c66c-b3a6-4edb-85bb-ea5617d036a4	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:55:26.187824+00	2026-11-09 21:40:58.883053+00	Devide Profile - AU915_1 - 1.0.3 - A (ABP)	AU915	1.0.3	A	default	JS	3600	1	f	f	t	{}	/**\n * Codec ChirpStack v4 — payload ASCII\n *\n * Uplink : bytes -> { text, length, hex, fPort }\n *   ex.: "QWRhaWxTaWx2YS1Jb1Q=" -> { "text": "AdailSilva-IoT", ... }\n * Downlink: { "text": "LED ON" } -> bytes ASCII\n */\n\nfunction decodeUplink(input) {\n  var bytes = input.bytes || [];\n  var warnings = [];\n\n  if (bytes.length === 0) {\n    return { errors: ["payload vazio"] };\n  }\n\n  var text = "";\n  var hex = [];\n  var nonPrintable = 0;\n\n  for (var i = 0; i < bytes.length; i++) {\n    var b = bytes[i] & 0xff;\n    hex.push((b < 16 ? "0" : "") + b.toString(16));\n\n    if (b >= 0x20 && b <= 0x7e) {\n      text += String.fromCharCode(b);          // ASCII imprimível\n    } else if (b === 0x0a || b === 0x0d || b === 0x09) {\n      text += String.fromCharCode(b);          // \\n \\r \\t\n    } else if (b === 0x00 && i === bytes.length - 1) {\n      // '\\0' final (string C): ignora\n    } else {\n      text += "?";\n      nonPrintable++;\n    }\n  }\n\n  if (nonPrintable > 0) {\n    warnings.push(nonPrintable + " byte(s) fora do ASCII imprimível substituído(s) por '?'");\n  }\n\n  return {\n    data: {\n      text: text,\n      length: bytes.length,\n      hex: hex.join(""),\n      fPort: input.fPort\n    },\n    warnings: warnings\n  };\n}\n\nfunction encodeDownlink(input) {\n  var text = input.data && input.data.text;\n\n  if (typeof text !== "string" || text.length === 0) {\n    return { errors: ["informe o campo 'text' (string não vazia)"] };\n  }\n\n  var bytes = [];\n  for (var i = 0; i < text.length; i++) {\n    var c = text.charCodeAt(i);\n    if (c > 0x7e) {\n      return { errors: ["caractere não ASCII na posição " + i + ": '" + text.charAt(i) + "'"] };\n    }\n    bytes.push(c);\n  }\n\n  return { bytes: bytes };\n}\n	t	Devide Profile Region AU915 - Region configuration 1 - MAC version LoRaWAN 1.0.3 - Regional parameters revision A (ABP)	{}	t	au915_1	f	0	{"rx2_dr": 8, "rx2_freq": 923300000, "rx1_delay": 1, "rx1_dr_offset": 0}	\N	{"timeout": 0}	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}	\N		0	{}
cff3ab28-afa3-4909-8958-e01ab4984a3b	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-10 14:34:42.556927+00	2026-11-09 21:41:41.282677+00	Devide Profile - AU915_1 - 1.0.3 - B (OTAA)	AU915	1.0.3	B	default	JS	3600	1	t	f	t	{}	/**\n * Codec ChirpStack v4 — payload ASCII\n *\n * Uplink : bytes -> { text, length, hex, fPort }\n *   ex.: "QWRhaWxTaWx2YS1Jb1Q=" -> { "text": "AdailSilva-IoT", ... }\n * Downlink: { "text": "LED ON" } -> bytes ASCII\n */\n\nfunction decodeUplink(input) {\n  var bytes = input.bytes || [];\n  var warnings = [];\n\n  if (bytes.length === 0) {\n    return { errors: ["payload vazio"] };\n  }\n\n  var text = "";\n  var hex = [];\n  var nonPrintable = 0;\n\n  for (var i = 0; i < bytes.length; i++) {\n    var b = bytes[i] & 0xff;\n    hex.push((b < 16 ? "0" : "") + b.toString(16));\n\n    if (b >= 0x20 && b <= 0x7e) {\n      text += String.fromCharCode(b);          // ASCII imprimível\n    } else if (b === 0x0a || b === 0x0d || b === 0x09) {\n      text += String.fromCharCode(b);          // \\n \\r \\t\n    } else if (b === 0x00 && i === bytes.length - 1) {\n      // '\\0' final (string C): ignora\n    } else {\n      text += "?";\n      nonPrintable++;\n    }\n  }\n\n  if (nonPrintable > 0) {\n    warnings.push(nonPrintable + " byte(s) fora do ASCII imprimível substituído(s) por '?'");\n  }\n\n  return {\n    data: {\n      text: text,\n      length: bytes.length,\n      hex: hex.join(""),\n      fPort: input.fPort\n    },\n    warnings: warnings\n  };\n}\n\nfunction encodeDownlink(input) {\n  var text = input.data && input.data.text;\n\n  if (typeof text !== "string" || text.length === 0) {\n    return { errors: ["informe o campo 'text' (string não vazia)"] };\n  }\n\n  var bytes = [];\n  for (var i = 0; i < text.length; i++) {\n    var c = text.charCodeAt(i);\n    if (c > 0x7e) {\n      return { errors: ["caractere não ASCII na posição " + i + ": '" + text.charAt(i) + "'"] };\n    }\n    bytes.push(c);\n  }\n\n  return { bytes: bytes };\n}\n	t	Devide Profile Region AU915 - Region configuration 1 - MAC version LoRaWAN 1.0.3 - Regional parameters revision B (OTAA)	{"hex": {"kind": "UNKNOWN", "name": ""}, "text": {"kind": "UNKNOWN", "name": ""}, "fPort": {"kind": "UNKNOWN", "name": ""}, "length": {"kind": "UNKNOWN", "name": ""}}	t	au915_1	f	0	\N	\N	{"timeout": 0}	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}	\N		0	{}
\.


--
-- TOC entry 3802 (class 0 OID 17789)
-- Dependencies: 243
-- Data for Name: device_profile_device; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device_profile_device (id, vendor_id, created_at, updated_at, name, description, metadata) FROM stdin;
\.


--
-- TOC entry 3785 (class 0 OID 17481)
-- Dependencies: 226
-- Data for Name: device_profile_template; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device_profile_template (id, created_at, updated_at, name, description, vendor, firmware, region, mac_version, reg_params_revision, adr_algorithm_id, payload_codec_runtime, payload_codec_script, uplink_interval, device_status_req_interval, flush_queue_on_activate, supports_otaa, supports_class_b, supports_class_c, class_b_timeout, class_b_ping_slot_periodicity, class_b_ping_slot_dr, class_b_ping_slot_freq, class_c_timeout, abp_rx1_delay, abp_rx1_dr_offset, abp_rx2_dr, abp_rx2_freq, tags, measurements, auto_detect_measurements) FROM stdin;
Devide_Profile_Template_AU915_1_0_3_A_ABP	2026-05-01 19:53:05.036281+00	2026-05-11 18:46:38.002088+00	Devide Profile Template - AU915 - 1.0.3 - A (ABP)	Devide Profile Template Region AU915 - MAC version LoRaWAN 1.0.3 - Regional parameters revision A (ABP)	AdailSilva-IoT	1.0	AU915	1.0.3	A	default	NONE	/**\n * Decode uplink function\n * \n * @param {object} input\n * @param {number[]} input.bytes Byte array containing the uplink payload, e.g. [255, 230, 255, 0]\n * @param {number} input.fPort Uplink fPort.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{data: object}} Object representing the decoded payload.\n */\nfunction decodeUplink(input) {\n  return {\n    data: {\n      // temp: 22.5\n    }\n  };\n}\n\n/**\n * Encode downlink function.\n * \n * @param {object} input\n * @param {object} input.data Object representing the payload that must be encoded.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{bytes: number[]}} Byte array containing the downlink payload.\n */\nfunction encodeDownlink(input) {\n  return {\n    // bytes: [225, 230, 255, 0]\n  };\n}\n	3600	1	t	f	f	t	0	0	0	0	5	1	0	8	923300000	{}	{}	t
Devide_Profile_Template_AU915_1_0_3_A_OTAA	2026-05-01 19:53:05.036281+00	2026-05-01 19:53:05.036281+00	Devide Profile Template - AU915 - 1.0.3 - A (OTAA)	Devide Profile Template Region AU915 - MAC version LoRaWAN 1.0.3 - Regional parameters revision A (OTAA)	AdailSilva-IoT	1.0	AU915	1.0.3	A	default	NONE	/**\n * Decode uplink function\n * \n * @param {object} input\n * @param {number[]} input.bytes Byte array containing the uplink payload, e.g. [255, 230, 255, 0]\n * @param {number} input.fPort Uplink fPort.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{data: object}} Object representing the decoded payload.\n */\nfunction decodeUplink(input) {\n  return {\n    data: {\n      // temp: 22.5\n    }\n  };\n}\n\n/**\n * Encode downlink function.\n * \n * @param {object} input\n * @param {object} input.data Object representing the payload that must be encoded.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{bytes: number[]}} Byte array containing the downlink payload.\n */\nfunction encodeDownlink(input) {\n  return {\n    // bytes: [225, 230, 255, 0]\n  };\n}\n	3600	1	t	t	f	t	0	0	0	0	5	0	0	0	0	{}	{}	t
Devide_Profile_Template_AU915_1_0_3_B_OTAA	2026-05-01 19:53:52.729292+00	2026-05-10 14:28:35.792411+00	Devide Profile Template - AU915 - 1.0.3 - B (OTAA)	Devide Profile Template Region AU915 - MAC version LoRaWAN 1.0.3 - Regional parameters revision B (OTAA)	AdailSilva-IoT	1.0	AU915	1.0.3	B	default	NONE	/**\n * Decode uplink function\n * \n * @param {object} input\n * @param {number[]} input.bytes Byte array containing the uplink payload, e.g. [255, 230, 255, 0]\n * @param {number} input.fPort Uplink fPort.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{data: object}} Object representing the decoded payload.\n */\nfunction decodeUplink(input) {\n  return {\n    data: {\n      // temp: 22.5\n    }\n  };\n}\n\n/**\n * Encode downlink function.\n * \n * @param {object} input\n * @param {object} input.data Object representing the payload that must be encoded.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{bytes: number[]}} Byte array containing the downlink payload.\n */\nfunction encodeDownlink(input) {\n  return {\n    // bytes: [225, 230, 255, 0]\n  };\n}\n	3600	1	t	t	f	t	0	0	0	0	5	0	0	0	0	{}	{}	t
Devide_Profile_Template_AU915_1_0_3_B_ABP	2026-05-01 19:53:52.729292+00	2026-05-11 18:46:45.616785+00	Devide Profile Template - AU915 - 1.0.3 - B (ABP)	Devide Profile Template Region AU915 - MAC version LoRaWAN 1.0.3 - Regional parameters revision B (ABP)	AdailSilva-IoT	1.0	AU915	1.0.3	B	default	NONE	/**\n * Decode uplink function\n * \n * @param {object} input\n * @param {number[]} input.bytes Byte array containing the uplink payload, e.g. [255, 230, 255, 0]\n * @param {number} input.fPort Uplink fPort.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{data: object}} Object representing the decoded payload.\n */\nfunction decodeUplink(input) {\n  return {\n    data: {\n      // temp: 22.5\n    }\n  };\n}\n\n/**\n * Encode downlink function.\n * \n * @param {object} input\n * @param {object} input.data Object representing the payload that must be encoded.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{bytes: number[]}} Byte array containing the downlink payload.\n */\nfunction encodeDownlink(input) {\n  return {\n    // bytes: [225, 230, 255, 0]\n  };\n}\n	3600	1	t	f	f	t	0	0	0	0	5	1	0	8	923300000	{}	{}	t
\.


--
-- TOC entry 3801 (class 0 OID 17779)
-- Dependencies: 242
-- Data for Name: device_profile_vendor; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device_profile_vendor (id, created_at, updated_at, name, vendor_id, ouis, metadata) FROM stdin;
\.


--
-- TOC entry 3786 (class 0 OID 17486)
-- Dependencies: 227
-- Data for Name: device_queue_item; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device_queue_item (id, dev_eui, created_at, f_port, confirmed, data, is_pending, f_cnt_down, timeout_after, is_encrypted, expires_at) FROM stdin;
\.


--
-- TOC entry 3787 (class 0 OID 17491)
-- Dependencies: 228
-- Data for Name: fuota_deployment; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.fuota_deployment (id, created_at, updated_at, started_at, completed_at, name, application_id, device_profile_id, multicast_addr, multicast_key, multicast_group_type, multicast_class_c_scheduling_type, multicast_dr, multicast_class_b_ping_slot_periodicity, multicast_frequency, multicast_timeout, multicast_session_start, multicast_session_end, unicast_max_retry_count, fragmentation_fragment_size, fragmentation_redundancy_percentage, fragmentation_session_index, fragmentation_matrix, fragmentation_block_ack_delay, fragmentation_descriptor, request_fragmentation_session_status, payload, on_complete_set_device_tags) FROM stdin;
\.


--
-- TOC entry 3788 (class 0 OID 17496)
-- Dependencies: 229
-- Data for Name: fuota_deployment_device; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.fuota_deployment_device (fuota_deployment_id, dev_eui, created_at, completed_at, mc_group_setup_completed_at, mc_session_completed_at, frag_session_setup_completed_at, frag_status_completed_at, error_msg) FROM stdin;
\.


--
-- TOC entry 3789 (class 0 OID 17501)
-- Dependencies: 230
-- Data for Name: fuota_deployment_gateway; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.fuota_deployment_gateway (fuota_deployment_id, gateway_id, created_at) FROM stdin;
\.


--
-- TOC entry 3790 (class 0 OID 17506)
-- Dependencies: 231
-- Data for Name: fuota_deployment_job; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.fuota_deployment_job (fuota_deployment_id, job, created_at, completed_at, max_retry_count, attempt_count, scheduler_run_after, warning_msg, error_msg) FROM stdin;
\.


--
-- TOC entry 3791 (class 0 OID 17511)
-- Dependencies: 232
-- Data for Name: gateway; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.gateway (gateway_id, tenant_id, created_at, updated_at, last_seen_at, name, description, latitude, longitude, altitude, stats_interval_secs, tls_certificate, tags, properties, downlink_priority) FROM stdin;
\\xe45f01fffe10e12e	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:58:53.71564+00	2026-05-01 19:58:53.71564+00	2026-05-16 17:43:02.886344+00	005-gtw-elecrow-001 | IP: 192.168.18.205	Elecrow RPi4-GPS (Multi Channel)	51.482594	-0.007661	0	30	\N	{}	{"region_config_id": "au915_1", "region_common_name": "AU915"}	10
\\xa840411b7dcc4150	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:59:14.136588+00	2026-05-01 19:59:14.136588+00	\N	006-gtw-dragino_lg02-001 | IP: 10.130.1.1	Dragino LG02 (Dual Channel)	51.482594	-0.007661	0	30	\N	{}	{}	10
\\xb827ebfffea04db6	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:57:06.297593+00	2026-11-09 20:28:00.28573+00	2026-10-06 14:10:08.032284+00	001-gtw-rak831-001 | IP: 192.168.18.201	RAK831 RPi3-GPS (Multi Channel)	-3.73041	-40.98801	0	30	\N	{}	{"region_config_id": "au915_1", "region_common_name": "AU915"}	10
\\xb827ebfffe158993	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:57:52.319327+00	2026-11-09 20:28:10.855955+00	2026-10-06 14:10:08.181173+00	002-gtw-radioenge-001 | IP: 192.168.18.202	Radioenge RPi3-RD43HATGPS (Multi Channel)	-3.73042	-40.98804	0	30	\N	{}	{"region_config_id": "au915_1", "region_common_name": "AU915"}	10
\\xb827ebfffef81e69	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:58:11.271739+00	2026-11-09 20:28:19.756505+00	2026-10-06 14:10:20.070019+00	003-gtw-radioenge-002 | IP: 192.168.18.203	Radioenge RPi3-RD43HATGPS (Multi Channel)	-3.73039	-40.98797	0	30	\N	{}	{"region_config_id": "au915_1", "region_common_name": "AU915"}	10
\\xb827ebfffe78ffce	3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 19:58:29.414872+00	2026-11-09 20:28:28.75735+00	2026-10-06 14:10:26.487966+00	004-gtw-radioenge-003 | IP: 192.168.18.204	Radioenge RPi3-RD43HATGPS (Multi Channel)	-3.7304	-40.98807	0	30	\N	{}	{"region_config_id": "au915_1", "region_common_name": "AU915"}	10
\\xa842e3fffe90a3d5	3e00683f-4c83-4c14-b1e1-afe543221836	2026-11-09 20:32:05.495236+00	2026-11-09 20:32:05.495236+00	\N	008-gtw-elecrow-002 | IP: 192.168.18.102	Elecrow RPi4-GPS (Multi Channel)	0	0	0	30	\N	{}	{}	10
\\xa842e3fffe90a3d4	3e00683f-4c83-4c14-b1e1-afe543221836	2026-11-09 20:30:47.616057+00	2026-11-09 20:30:47.616057+00	2026-11-11 12:15:56.141622+00	007-gtw-radioenge-004 | IP: 192.168.18.101	Radioenge RPi3-RD43HATGPS (Multi Channel)	-3.7304	-40.98819	779	30	\N	{}	{"gateway": "Gateway ESP32 with SX1301", "version": "0.0.0-dev", "region_config_id": "au915_1", "region_common_name": "AU915"}	10
\.


--
-- TOC entry 3792 (class 0 OID 17516)
-- Dependencies: 233
-- Data for Name: multicast_group; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.multicast_group (id, application_id, created_at, updated_at, name, region, mc_addr, mc_nwk_s_key, mc_app_s_key, f_cnt, group_type, dr, frequency, class_b_ping_slot_periodicity, class_c_scheduling_type) FROM stdin;
\.


--
-- TOC entry 3793 (class 0 OID 17521)
-- Dependencies: 234
-- Data for Name: multicast_group_device; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.multicast_group_device (multicast_group_id, dev_eui, created_at) FROM stdin;
\.


--
-- TOC entry 3794 (class 0 OID 17526)
-- Dependencies: 235
-- Data for Name: multicast_group_gateway; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.multicast_group_gateway (multicast_group_id, gateway_id, created_at) FROM stdin;
\.


--
-- TOC entry 3795 (class 0 OID 17531)
-- Dependencies: 236
-- Data for Name: multicast_group_queue_item; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.multicast_group_queue_item (id, created_at, scheduler_run_after, multicast_group_id, gateway_id, f_cnt, f_port, data, emit_at_time_since_gps_epoch, expires_at) FROM stdin;
\.


--
-- TOC entry 3796 (class 0 OID 17536)
-- Dependencies: 237
-- Data for Name: relay_device; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.relay_device (relay_dev_eui, dev_eui, created_at) FROM stdin;
\.


--
-- TOC entry 3797 (class 0 OID 17541)
-- Dependencies: 238
-- Data for Name: relay_gateway; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.relay_gateway (tenant_id, relay_id, created_at, updated_at, last_seen_at, name, description, stats_interval_secs, region_config_id) FROM stdin;
\.


--
-- TOC entry 3798 (class 0 OID 17546)
-- Dependencies: 239
-- Data for Name: tenant; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.tenant (id, created_at, updated_at, name, description, can_have_gateways, max_device_count, max_gateway_count, private_gateways_up, private_gateways_down, tags, dev_addr_prefixes) FROM stdin;
3e00683f-4c83-4c14-b1e1-afe543221836	2026-05-01 16:21:10.253969+00	2026-05-08 16:23:47.31098+00	ChirpStack	AdailSilva-IoT	t	0	0	f	f	{}	{}
\.


--
-- TOC entry 3799 (class 0 OID 17551)
-- Dependencies: 240
-- Data for Name: tenant_user; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.tenant_user (tenant_id, user_id, created_at, updated_at, is_admin, is_device_admin, is_gateway_admin) FROM stdin;
3e00683f-4c83-4c14-b1e1-afe543221836	0bd2b7e7-d684-42d9-8192-51d88da073a9	2026-05-07 11:59:41.679769+00	2026-05-07 11:59:41.679769+00	t	t	t
\.


--
-- TOC entry 3800 (class 0 OID 17554)
-- Dependencies: 241
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public."user" (id, external_id, created_at, updated_at, is_admin, is_active, email, email_verified, password_hash, note) FROM stdin;
0bd2b7e7-d684-42d9-8192-51d88da073a9	\N	2026-05-01 16:21:10.253969+00	2026-05-01 19:51:17.844022+00	t	t	adail101@hotmail.com	t	$pbkdf2-sha512$i=10000,l=32$76PaUrTF97tEoFyYtj8RUg$n6jMj5UHYDu9XdHXsvNSerK2S8C5H5vq/txk/Ojm328	AdailSilva-IoT
\.


--
-- TOC entry 3515 (class 2606 OID 17560)
-- Name: __diesel_schema_migrations __diesel_schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.__diesel_schema_migrations
    ADD CONSTRAINT __diesel_schema_migrations_pkey PRIMARY KEY (version);


--
-- TOC entry 3517 (class 2606 OID 17562)
-- Name: api_key api_key_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.api_key
    ADD CONSTRAINT api_key_pkey PRIMARY KEY (id);


--
-- TOC entry 3525 (class 2606 OID 17564)
-- Name: application_integration application_integration_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.application_integration
    ADD CONSTRAINT application_integration_pkey PRIMARY KEY (application_id, kind);


--
-- TOC entry 3520 (class 2606 OID 17566)
-- Name: application application_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.application
    ADD CONSTRAINT application_pkey PRIMARY KEY (id);


--
-- TOC entry 3537 (class 2606 OID 17568)
-- Name: device_keys device_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_keys
    ADD CONSTRAINT device_keys_pkey PRIMARY KEY (dev_eui);


--
-- TOC entry 3527 (class 2606 OID 17570)
-- Name: device device_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_pkey PRIMARY KEY (dev_eui);


--
-- TOC entry 3600 (class 2606 OID 17795)
-- Name: device_profile_device device_profile_device_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_profile_device
    ADD CONSTRAINT device_profile_device_pkey PRIMARY KEY (id);


--
-- TOC entry 3539 (class 2606 OID 17572)
-- Name: device_profile device_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_profile
    ADD CONSTRAINT device_profile_pkey PRIMARY KEY (id);


--
-- TOC entry 3545 (class 2606 OID 17574)
-- Name: device_profile_template device_profile_template_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_profile_template
    ADD CONSTRAINT device_profile_template_pkey PRIMARY KEY (id);


--
-- TOC entry 3595 (class 2606 OID 17785)
-- Name: device_profile_vendor device_profile_vendor_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_profile_vendor
    ADD CONSTRAINT device_profile_vendor_pkey PRIMARY KEY (id);


--
-- TOC entry 3547 (class 2606 OID 17576)
-- Name: device_queue_item device_queue_item_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_queue_item
    ADD CONSTRAINT device_queue_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3554 (class 2606 OID 17578)
-- Name: fuota_deployment_device fuota_deployment_device_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_device
    ADD CONSTRAINT fuota_deployment_device_pkey PRIMARY KEY (fuota_deployment_id, dev_eui);


--
-- TOC entry 3556 (class 2606 OID 17580)
-- Name: fuota_deployment_gateway fuota_deployment_gateway_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_gateway
    ADD CONSTRAINT fuota_deployment_gateway_pkey PRIMARY KEY (fuota_deployment_id, gateway_id);


--
-- TOC entry 3558 (class 2606 OID 17582)
-- Name: fuota_deployment_job fuota_deployment_job_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_job
    ADD CONSTRAINT fuota_deployment_job_pkey PRIMARY KEY (fuota_deployment_id, job);


--
-- TOC entry 3552 (class 2606 OID 17584)
-- Name: fuota_deployment fuota_deployment_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment
    ADD CONSTRAINT fuota_deployment_pkey PRIMARY KEY (id);


--
-- TOC entry 3562 (class 2606 OID 17586)
-- Name: gateway gateway_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_pkey PRIMARY KEY (gateway_id);


--
-- TOC entry 3572 (class 2606 OID 17588)
-- Name: multicast_group_device multicast_group_device_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_device
    ADD CONSTRAINT multicast_group_device_pkey PRIMARY KEY (multicast_group_id, dev_eui);


--
-- TOC entry 3574 (class 2606 OID 17590)
-- Name: multicast_group_gateway multicast_group_gateway_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_gateway
    ADD CONSTRAINT multicast_group_gateway_pkey PRIMARY KEY (multicast_group_id, gateway_id);


--
-- TOC entry 3570 (class 2606 OID 17592)
-- Name: multicast_group multicast_group_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group
    ADD CONSTRAINT multicast_group_pkey PRIMARY KEY (id);


--
-- TOC entry 3578 (class 2606 OID 17594)
-- Name: multicast_group_queue_item multicast_group_queue_item_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_queue_item
    ADD CONSTRAINT multicast_group_queue_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3580 (class 2606 OID 17596)
-- Name: relay_device relay_device_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.relay_device
    ADD CONSTRAINT relay_device_pkey PRIMARY KEY (relay_dev_eui, dev_eui);


--
-- TOC entry 3582 (class 2606 OID 17598)
-- Name: relay_gateway relay_gateway_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.relay_gateway
    ADD CONSTRAINT relay_gateway_pkey PRIMARY KEY (tenant_id, relay_id);


--
-- TOC entry 3586 (class 2606 OID 17600)
-- Name: tenant tenant_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.tenant
    ADD CONSTRAINT tenant_pkey PRIMARY KEY (id);


--
-- TOC entry 3589 (class 2606 OID 17602)
-- Name: tenant_user tenant_user_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.tenant_user
    ADD CONSTRAINT tenant_user_pkey PRIMARY KEY (tenant_id, user_id);


--
-- TOC entry 3593 (class 2606 OID 17604)
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- TOC entry 3518 (class 1259 OID 17605)
-- Name: idx_api_key_tenant_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_api_key_tenant_id ON public.api_key USING btree (tenant_id);


--
-- TOC entry 3521 (class 1259 OID 17606)
-- Name: idx_application_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_application_name_trgm ON public.application USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3522 (class 1259 OID 17607)
-- Name: idx_application_tags; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_application_tags ON public.application USING gin (tags);


--
-- TOC entry 3523 (class 1259 OID 17608)
-- Name: idx_application_tenant_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_application_tenant_id ON public.application USING btree (tenant_id);


--
-- TOC entry 3528 (class 1259 OID 17609)
-- Name: idx_device_application_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_application_id ON public.device USING btree (application_id);


--
-- TOC entry 3529 (class 1259 OID 17610)
-- Name: idx_device_dev_addr; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_dev_addr ON public.device USING btree (dev_addr);


--
-- TOC entry 3530 (class 1259 OID 17611)
-- Name: idx_device_dev_addr_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_dev_addr_trgm ON public.device USING gin (encode(dev_addr, 'hex'::text) public.gin_trgm_ops);


--
-- TOC entry 3531 (class 1259 OID 17612)
-- Name: idx_device_dev_eui_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_dev_eui_trgm ON public.device USING gin (encode(dev_eui, 'hex'::text) public.gin_trgm_ops);


--
-- TOC entry 3532 (class 1259 OID 17613)
-- Name: idx_device_device_profile_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_device_profile_id ON public.device USING btree (device_profile_id);


--
-- TOC entry 3533 (class 1259 OID 17614)
-- Name: idx_device_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_name_trgm ON public.device USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3540 (class 1259 OID 17810)
-- Name: idx_device_profile_device_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_device_id ON public.device_profile USING btree (device_id);


--
-- TOC entry 3601 (class 1259 OID 17802)
-- Name: idx_device_profile_device_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_device_name_trgm ON public.device_profile_device USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3602 (class 1259 OID 17801)
-- Name: idx_device_profile_device_vendor_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_device_vendor_id ON public.device_profile_device USING btree (vendor_id);


--
-- TOC entry 3541 (class 1259 OID 17615)
-- Name: idx_device_profile_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_name_trgm ON public.device_profile USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3542 (class 1259 OID 17616)
-- Name: idx_device_profile_tags; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_tags ON public.device_profile USING gin (tags);


--
-- TOC entry 3543 (class 1259 OID 17617)
-- Name: idx_device_profile_tenant_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_tenant_id ON public.device_profile USING btree (tenant_id);


--
-- TOC entry 3596 (class 1259 OID 17786)
-- Name: idx_device_profile_vendor_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_vendor_name_trgm ON public.device_profile_vendor USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3597 (class 1259 OID 17787)
-- Name: idx_device_profile_vendor_ouis; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_vendor_ouis ON public.device_profile_vendor USING btree (ouis);


--
-- TOC entry 3598 (class 1259 OID 17788)
-- Name: idx_device_profile_vendor_vendor_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_vendor_vendor_id ON public.device_profile_vendor USING btree (vendor_id);


--
-- TOC entry 3548 (class 1259 OID 17618)
-- Name: idx_device_queue_item_created_at; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_queue_item_created_at ON public.device_queue_item USING btree (created_at);


--
-- TOC entry 3549 (class 1259 OID 17619)
-- Name: idx_device_queue_item_dev_eui; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_queue_item_dev_eui ON public.device_queue_item USING btree (dev_eui);


--
-- TOC entry 3550 (class 1259 OID 17620)
-- Name: idx_device_queue_item_timeout_after; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_queue_item_timeout_after ON public.device_queue_item USING btree (timeout_after);


--
-- TOC entry 3534 (class 1259 OID 17621)
-- Name: idx_device_secondary_dev_addr; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_secondary_dev_addr ON public.device USING btree (secondary_dev_addr);


--
-- TOC entry 3535 (class 1259 OID 17622)
-- Name: idx_device_tags; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_tags ON public.device USING gin (tags);


--
-- TOC entry 3559 (class 1259 OID 17623)
-- Name: idx_fuota_deployment_job_completed_at; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_fuota_deployment_job_completed_at ON public.fuota_deployment_job USING btree (completed_at);


--
-- TOC entry 3560 (class 1259 OID 17624)
-- Name: idx_fuota_deployment_job_scheduler_run_after; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_fuota_deployment_job_scheduler_run_after ON public.fuota_deployment_job USING btree (scheduler_run_after);


--
-- TOC entry 3563 (class 1259 OID 17625)
-- Name: idx_gateway_id_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_gateway_id_trgm ON public.gateway USING gin (encode(gateway_id, 'hex'::text) public.gin_trgm_ops);


--
-- TOC entry 3564 (class 1259 OID 17626)
-- Name: idx_gateway_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_gateway_name_trgm ON public.gateway USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3565 (class 1259 OID 17627)
-- Name: idx_gateway_tags; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_gateway_tags ON public.gateway USING gin (tags);


--
-- TOC entry 3566 (class 1259 OID 17628)
-- Name: idx_gateway_tenant_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_gateway_tenant_id ON public.gateway USING btree (tenant_id);


--
-- TOC entry 3567 (class 1259 OID 17629)
-- Name: idx_multicast_group_application_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_multicast_group_application_id ON public.multicast_group USING btree (application_id);


--
-- TOC entry 3568 (class 1259 OID 17630)
-- Name: idx_multicast_group_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_multicast_group_name_trgm ON public.multicast_group USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3575 (class 1259 OID 17631)
-- Name: idx_multicast_group_queue_item_multicast_group_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_multicast_group_queue_item_multicast_group_id ON public.multicast_group_queue_item USING btree (multicast_group_id);


--
-- TOC entry 3576 (class 1259 OID 17632)
-- Name: idx_multicast_group_queue_item_scheduler_run_after; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_multicast_group_queue_item_scheduler_run_after ON public.multicast_group_queue_item USING btree (scheduler_run_after);


--
-- TOC entry 3583 (class 1259 OID 17633)
-- Name: idx_tenant_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_tenant_name_trgm ON public.tenant USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3584 (class 1259 OID 17634)
-- Name: idx_tenant_tags; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_tenant_tags ON public.tenant USING gin (tags);


--
-- TOC entry 3587 (class 1259 OID 17635)
-- Name: idx_tenant_user_user_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_tenant_user_user_id ON public.tenant_user USING btree (user_id);


--
-- TOC entry 3590 (class 1259 OID 17636)
-- Name: idx_user_email; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE UNIQUE INDEX idx_user_email ON public."user" USING btree (email);


--
-- TOC entry 3591 (class 1259 OID 17637)
-- Name: idx_user_external_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE UNIQUE INDEX idx_user_external_id ON public."user" USING btree (external_id);


--
-- TOC entry 3603 (class 2606 OID 17638)
-- Name: api_key api_key_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.api_key
    ADD CONSTRAINT api_key_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id) ON DELETE CASCADE;


--
-- TOC entry 3605 (class 2606 OID 17643)
-- Name: application_integration application_integration_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.application_integration
    ADD CONSTRAINT application_integration_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.application(id) ON DELETE CASCADE;


--
-- TOC entry 3604 (class 2606 OID 17648)
-- Name: application application_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.application
    ADD CONSTRAINT application_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id) ON DELETE CASCADE;


--
-- TOC entry 3606 (class 2606 OID 17653)
-- Name: device device_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.application(id) ON DELETE CASCADE;


--
-- TOC entry 3607 (class 2606 OID 17658)
-- Name: device device_device_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_device_profile_id_fkey FOREIGN KEY (device_profile_id) REFERENCES public.device_profile(id) ON DELETE CASCADE;


--
-- TOC entry 3608 (class 2606 OID 17663)
-- Name: device_keys device_keys_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_keys
    ADD CONSTRAINT device_keys_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3609 (class 2606 OID 17805)
-- Name: device_profile device_profile_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_profile
    ADD CONSTRAINT device_profile_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.device_profile_device(id) ON DELETE CASCADE;


--
-- TOC entry 3632 (class 2606 OID 17796)
-- Name: device_profile_device device_profile_device_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_profile_device
    ADD CONSTRAINT device_profile_device_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.device_profile_vendor(id) ON DELETE CASCADE;


--
-- TOC entry 3610 (class 2606 OID 17668)
-- Name: device_profile device_profile_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_profile
    ADD CONSTRAINT device_profile_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id) ON DELETE CASCADE;


--
-- TOC entry 3611 (class 2606 OID 17673)
-- Name: device_queue_item device_queue_item_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_queue_item
    ADD CONSTRAINT device_queue_item_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3612 (class 2606 OID 17678)
-- Name: fuota_deployment fuota_deployment_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment
    ADD CONSTRAINT fuota_deployment_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.application(id) ON DELETE CASCADE;


--
-- TOC entry 3614 (class 2606 OID 17683)
-- Name: fuota_deployment_device fuota_deployment_device_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_device
    ADD CONSTRAINT fuota_deployment_device_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3615 (class 2606 OID 17688)
-- Name: fuota_deployment_device fuota_deployment_device_fuota_deployment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_device
    ADD CONSTRAINT fuota_deployment_device_fuota_deployment_id_fkey FOREIGN KEY (fuota_deployment_id) REFERENCES public.fuota_deployment(id) ON DELETE CASCADE;


--
-- TOC entry 3613 (class 2606 OID 17693)
-- Name: fuota_deployment fuota_deployment_device_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment
    ADD CONSTRAINT fuota_deployment_device_profile_id_fkey FOREIGN KEY (device_profile_id) REFERENCES public.device_profile(id) ON DELETE CASCADE;


--
-- TOC entry 3616 (class 2606 OID 17698)
-- Name: fuota_deployment_gateway fuota_deployment_gateway_fuota_deployment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_gateway
    ADD CONSTRAINT fuota_deployment_gateway_fuota_deployment_id_fkey FOREIGN KEY (fuota_deployment_id) REFERENCES public.fuota_deployment(id) ON DELETE CASCADE;


--
-- TOC entry 3617 (class 2606 OID 17703)
-- Name: fuota_deployment_gateway fuota_deployment_gateway_gateway_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_gateway
    ADD CONSTRAINT fuota_deployment_gateway_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES public.gateway(gateway_id) ON DELETE CASCADE;


--
-- TOC entry 3618 (class 2606 OID 17708)
-- Name: fuota_deployment_job fuota_deployment_job_fuota_deployment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_job
    ADD CONSTRAINT fuota_deployment_job_fuota_deployment_id_fkey FOREIGN KEY (fuota_deployment_id) REFERENCES public.fuota_deployment(id) ON DELETE CASCADE;


--
-- TOC entry 3619 (class 2606 OID 17713)
-- Name: gateway gateway_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id) ON DELETE CASCADE;


--
-- TOC entry 3620 (class 2606 OID 17718)
-- Name: multicast_group multicast_group_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group
    ADD CONSTRAINT multicast_group_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.application(id) ON DELETE CASCADE;


--
-- TOC entry 3621 (class 2606 OID 17723)
-- Name: multicast_group_device multicast_group_device_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_device
    ADD CONSTRAINT multicast_group_device_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3622 (class 2606 OID 17728)
-- Name: multicast_group_device multicast_group_device_multicast_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_device
    ADD CONSTRAINT multicast_group_device_multicast_group_id_fkey FOREIGN KEY (multicast_group_id) REFERENCES public.multicast_group(id) ON DELETE CASCADE;


--
-- TOC entry 3623 (class 2606 OID 17733)
-- Name: multicast_group_gateway multicast_group_gateway_gateway_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_gateway
    ADD CONSTRAINT multicast_group_gateway_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES public.gateway(gateway_id) ON DELETE CASCADE;


--
-- TOC entry 3624 (class 2606 OID 17738)
-- Name: multicast_group_gateway multicast_group_gateway_multicast_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_gateway
    ADD CONSTRAINT multicast_group_gateway_multicast_group_id_fkey FOREIGN KEY (multicast_group_id) REFERENCES public.multicast_group(id) ON DELETE CASCADE;


--
-- TOC entry 3625 (class 2606 OID 17743)
-- Name: multicast_group_queue_item multicast_group_queue_item_gateway_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_queue_item
    ADD CONSTRAINT multicast_group_queue_item_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES public.gateway(gateway_id) ON DELETE CASCADE;


--
-- TOC entry 3626 (class 2606 OID 17748)
-- Name: multicast_group_queue_item multicast_group_queue_item_multicast_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_queue_item
    ADD CONSTRAINT multicast_group_queue_item_multicast_group_id_fkey FOREIGN KEY (multicast_group_id) REFERENCES public.multicast_group(id) ON DELETE CASCADE;


--
-- TOC entry 3627 (class 2606 OID 17753)
-- Name: relay_device relay_device_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.relay_device
    ADD CONSTRAINT relay_device_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3628 (class 2606 OID 17758)
-- Name: relay_device relay_device_relay_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.relay_device
    ADD CONSTRAINT relay_device_relay_dev_eui_fkey FOREIGN KEY (relay_dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3629 (class 2606 OID 17763)
-- Name: relay_gateway relay_gateway_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.relay_gateway
    ADD CONSTRAINT relay_gateway_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id) ON DELETE CASCADE;


--
-- TOC entry 3630 (class 2606 OID 17768)
-- Name: tenant_user tenant_user_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.tenant_user
    ADD CONSTRAINT tenant_user_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id) ON DELETE CASCADE;


--
-- TOC entry 3631 (class 2606 OID 17773)
-- Name: tenant_user tenant_user_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.tenant_user
    ADD CONSTRAINT tenant_user_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


-- Completed on 2026-11-11 09:16:13 -03

--
-- PostgreSQL database dump complete
--

\unrestrict d5RccxLFRtL7Q9xbeuwbUEQF1cWdR72phd17X9j0Cb4rNA4Pl0sHEo0QH5uIlZY

