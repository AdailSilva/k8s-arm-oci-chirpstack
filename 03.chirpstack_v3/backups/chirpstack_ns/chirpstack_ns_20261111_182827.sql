--
-- PostgreSQL database dump
--

\restrict razZQ3dpJ6NybUsHybFFb908HyEO1Uw1WEfegvV0cBf9tHfd1nDFJpuF4tEtOAk

-- Dumped from database version 14.24
-- Dumped by pg_dump version 17.11 (Ubuntu 17.11-1.pgdg24.04+2)

-- Started on 2026-11-11 18:28:49 -03

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

DROP DATABASE IF EXISTS chirpstack_ns;
--
-- TOC entry 3586 (class 1262 OID 17054)
-- Name: chirpstack_ns; Type: DATABASE; Schema: -; Owner: chirpstack_ns
--

CREATE DATABASE chirpstack_ns WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'C';


ALTER DATABASE chirpstack_ns OWNER TO chirpstack_ns;

\unrestrict razZQ3dpJ6NybUsHybFFb908HyEO1Uw1WEfegvV0cBf9tHfd1nDFJpuF4tEtOAk
\connect chirpstack_ns
\restrict razZQ3dpJ6NybUsHybFFb908HyEO1Uw1WEfegvV0cBf9tHfd1nDFJpuF4tEtOAk

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
-- TOC entry 5 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 211 (class 1259 OID 17055)
-- Name: code_migration; Type: TABLE; Schema: public; Owner: chirpstack_ns
--

CREATE TABLE public.code_migration (
    id text NOT NULL,
    applied_at timestamp with time zone NOT NULL
);


ALTER TABLE public.code_migration OWNER TO chirpstack_ns;

--
-- TOC entry 212 (class 1259 OID 17060)
-- Name: device; Type: TABLE; Schema: public; Owner: chirpstack_ns
--

CREATE TABLE public.device (
    dev_eui bytea NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    device_profile_id uuid NOT NULL,
    service_profile_id uuid NOT NULL,
    routing_profile_id uuid NOT NULL,
    skip_fcnt_check boolean DEFAULT false NOT NULL,
    reference_altitude double precision NOT NULL,
    mode character(1) NOT NULL,
    is_disabled boolean NOT NULL
);


ALTER TABLE public.device OWNER TO chirpstack_ns;

--
-- TOC entry 213 (class 1259 OID 17066)
-- Name: device_activation; Type: TABLE; Schema: public; Owner: chirpstack_ns
--

CREATE TABLE public.device_activation (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    dev_eui bytea NOT NULL,
    join_eui bytea NOT NULL,
    dev_addr bytea NOT NULL,
    f_nwk_s_int_key bytea NOT NULL,
    s_nwk_s_int_key bytea NOT NULL,
    nwk_s_enc_key bytea NOT NULL,
    dev_nonce integer NOT NULL,
    join_req_type smallint NOT NULL
);


ALTER TABLE public.device_activation OWNER TO chirpstack_ns;

--
-- TOC entry 214 (class 1259 OID 17071)
-- Name: device_activation_id_seq; Type: SEQUENCE; Schema: public; Owner: chirpstack_ns
--

CREATE SEQUENCE public.device_activation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.device_activation_id_seq OWNER TO chirpstack_ns;

--
-- TOC entry 3588 (class 0 OID 0)
-- Dependencies: 214
-- Name: device_activation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chirpstack_ns
--

ALTER SEQUENCE public.device_activation_id_seq OWNED BY public.device_activation.id;


--
-- TOC entry 215 (class 1259 OID 17072)
-- Name: device_multicast_group; Type: TABLE; Schema: public; Owner: chirpstack_ns
--

CREATE TABLE public.device_multicast_group (
    dev_eui bytea NOT NULL,
    multicast_group_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.device_multicast_group OWNER TO chirpstack_ns;

--
-- TOC entry 216 (class 1259 OID 17077)
-- Name: device_profile; Type: TABLE; Schema: public; Owner: chirpstack_ns
--

CREATE TABLE public.device_profile (
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    device_profile_id uuid NOT NULL,
    supports_class_b boolean NOT NULL,
    class_b_timeout integer NOT NULL,
    ping_slot_period integer NOT NULL,
    ping_slot_dr integer NOT NULL,
    ping_slot_freq bigint NOT NULL,
    supports_class_c boolean NOT NULL,
    class_c_timeout integer NOT NULL,
    mac_version character varying(10) NOT NULL,
    reg_params_revision character varying(20) NOT NULL,
    rx_delay_1 integer NOT NULL,
    rx_dr_offset_1 integer NOT NULL,
    rx_data_rate_2 integer NOT NULL,
    rx_freq_2 bigint NOT NULL,
    factory_preset_freqs bigint[],
    max_eirp integer NOT NULL,
    max_duty_cycle integer NOT NULL,
    supports_join boolean NOT NULL,
    rf_region character varying(20) NOT NULL,
    supports_32bit_fcnt boolean NOT NULL,
    adr_algorithm_id character varying(100) NOT NULL
);


ALTER TABLE public.device_profile OWNER TO chirpstack_ns;

--
-- TOC entry 217 (class 1259 OID 17082)
-- Name: device_queue; Type: TABLE; Schema: public; Owner: chirpstack_ns
--

CREATE TABLE public.device_queue (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    dev_eui bytea,
    frm_payload bytea,
    f_cnt integer NOT NULL,
    f_port integer NOT NULL,
    confirmed boolean NOT NULL,
    is_pending boolean NOT NULL,
    timeout_after timestamp with time zone,
    emit_at_time_since_gps_epoch bigint,
    dev_addr bytea,
    retry_after timestamp with time zone
);


ALTER TABLE public.device_queue OWNER TO chirpstack_ns;

--
-- TOC entry 218 (class 1259 OID 17087)
-- Name: device_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: chirpstack_ns
--

CREATE SEQUENCE public.device_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.device_queue_id_seq OWNER TO chirpstack_ns;

--
-- TOC entry 3589 (class 0 OID 0)
-- Dependencies: 218
-- Name: device_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chirpstack_ns
--

ALTER SEQUENCE public.device_queue_id_seq OWNED BY public.device_queue.id;


--
-- TOC entry 219 (class 1259 OID 17088)
-- Name: gateway; Type: TABLE; Schema: public; Owner: chirpstack_ns
--

CREATE TABLE public.gateway (
    gateway_id bytea NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    first_seen_at timestamp with time zone,
    last_seen_at timestamp with time zone,
    location point NOT NULL,
    altitude double precision NOT NULL,
    gateway_profile_id uuid,
    routing_profile_id uuid NOT NULL,
    tls_cert bytea,
    service_profile_id uuid
);


ALTER TABLE public.gateway OWNER TO chirpstack_ns;

--
-- TOC entry 220 (class 1259 OID 17093)
-- Name: gateway_board; Type: TABLE; Schema: public; Owner: chirpstack_ns
--

CREATE TABLE public.gateway_board (
    id smallint NOT NULL,
    gateway_id bytea NOT NULL,
    fpga_id bytea,
    fine_timestamp_key bytea
);


ALTER TABLE public.gateway_board OWNER TO chirpstack_ns;

--
-- TOC entry 221 (class 1259 OID 17098)
-- Name: gateway_profile; Type: TABLE; Schema: public; Owner: chirpstack_ns
--

CREATE TABLE public.gateway_profile (
    gateway_profile_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    channels smallint[] NOT NULL,
    stats_interval bigint NOT NULL
);


ALTER TABLE public.gateway_profile OWNER TO chirpstack_ns;

--
-- TOC entry 222 (class 1259 OID 17103)
-- Name: gateway_profile_extra_channel; Type: TABLE; Schema: public; Owner: chirpstack_ns
--

CREATE TABLE public.gateway_profile_extra_channel (
    id bigint NOT NULL,
    gateway_profile_id uuid NOT NULL,
    modulation character varying(10) NOT NULL,
    frequency integer NOT NULL,
    bandwidth integer NOT NULL,
    bitrate integer NOT NULL,
    spreading_factors smallint[]
);


ALTER TABLE public.gateway_profile_extra_channel OWNER TO chirpstack_ns;

--
-- TOC entry 223 (class 1259 OID 17108)
-- Name: gateway_profile_extra_channel_id_seq; Type: SEQUENCE; Schema: public; Owner: chirpstack_ns
--

CREATE SEQUENCE public.gateway_profile_extra_channel_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gateway_profile_extra_channel_id_seq OWNER TO chirpstack_ns;

--
-- TOC entry 3590 (class 0 OID 0)
-- Dependencies: 223
-- Name: gateway_profile_extra_channel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chirpstack_ns
--

ALTER SEQUENCE public.gateway_profile_extra_channel_id_seq OWNED BY public.gateway_profile_extra_channel.id;


--
-- TOC entry 224 (class 1259 OID 17109)
-- Name: multicast_group; Type: TABLE; Schema: public; Owner: chirpstack_ns
--

CREATE TABLE public.multicast_group (
    id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    mc_addr bytea,
    mc_nwk_s_key bytea,
    f_cnt integer NOT NULL,
    group_type character(1) NOT NULL,
    dr integer NOT NULL,
    frequency bigint NOT NULL,
    ping_slot_period integer NOT NULL,
    routing_profile_id uuid NOT NULL,
    service_profile_id uuid NOT NULL
);


ALTER TABLE public.multicast_group OWNER TO chirpstack_ns;

--
-- TOC entry 225 (class 1259 OID 17114)
-- Name: multicast_queue; Type: TABLE; Schema: public; Owner: chirpstack_ns
--

CREATE TABLE public.multicast_queue (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    schedule_at timestamp with time zone NOT NULL,
    emit_at_time_since_gps_epoch bigint,
    multicast_group_id uuid NOT NULL,
    gateway_id bytea NOT NULL,
    f_cnt integer NOT NULL,
    f_port integer NOT NULL,
    frm_payload bytea,
    updated_at timestamp with time zone NOT NULL,
    retry_after timestamp with time zone
);


ALTER TABLE public.multicast_queue OWNER TO chirpstack_ns;

--
-- TOC entry 226 (class 1259 OID 17119)
-- Name: multicast_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: chirpstack_ns
--

CREATE SEQUENCE public.multicast_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.multicast_queue_id_seq OWNER TO chirpstack_ns;

--
-- TOC entry 3591 (class 0 OID 0)
-- Dependencies: 226
-- Name: multicast_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chirpstack_ns
--

ALTER SEQUENCE public.multicast_queue_id_seq OWNED BY public.multicast_queue.id;


--
-- TOC entry 227 (class 1259 OID 17120)
-- Name: routing_profile; Type: TABLE; Schema: public; Owner: chirpstack_ns
--

CREATE TABLE public.routing_profile (
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    routing_profile_id uuid NOT NULL,
    as_id character varying(255),
    ca_cert text DEFAULT ''::text NOT NULL,
    tls_cert text DEFAULT ''::text NOT NULL,
    tls_key text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.routing_profile OWNER TO chirpstack_ns;

--
-- TOC entry 228 (class 1259 OID 17128)
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: chirpstack_ns
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    dirty boolean NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO chirpstack_ns;

--
-- TOC entry 229 (class 1259 OID 17131)
-- Name: service_profile; Type: TABLE; Schema: public; Owner: chirpstack_ns
--

CREATE TABLE public.service_profile (
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    service_profile_id uuid NOT NULL,
    ul_rate integer NOT NULL,
    ul_bucket_size integer NOT NULL,
    ul_rate_policy character(4) NOT NULL,
    dl_rate integer NOT NULL,
    dl_bucket_size integer NOT NULL,
    dl_rate_policy character(4) NOT NULL,
    add_gw_metadata boolean NOT NULL,
    dev_status_req_freq integer NOT NULL,
    report_dev_status_battery boolean NOT NULL,
    report_dev_status_margin boolean NOT NULL,
    dr_min integer NOT NULL,
    dr_max integer NOT NULL,
    channel_mask bytea,
    pr_allowed boolean NOT NULL,
    hr_allowed boolean NOT NULL,
    ra_allowed boolean NOT NULL,
    nwk_geo_loc boolean NOT NULL,
    target_per integer NOT NULL,
    min_gw_diversity integer NOT NULL,
    gws_private boolean DEFAULT false NOT NULL
);


ALTER TABLE public.service_profile OWNER TO chirpstack_ns;

--
-- TOC entry 3350 (class 2604 OID 17137)
-- Name: device_activation id; Type: DEFAULT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_activation ALTER COLUMN id SET DEFAULT nextval('public.device_activation_id_seq'::regclass);


--
-- TOC entry 3351 (class 2604 OID 17138)
-- Name: device_queue id; Type: DEFAULT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_queue ALTER COLUMN id SET DEFAULT nextval('public.device_queue_id_seq'::regclass);


--
-- TOC entry 3352 (class 2604 OID 17139)
-- Name: gateway_profile_extra_channel id; Type: DEFAULT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway_profile_extra_channel ALTER COLUMN id SET DEFAULT nextval('public.gateway_profile_extra_channel_id_seq'::regclass);


--
-- TOC entry 3353 (class 2604 OID 17140)
-- Name: multicast_queue id; Type: DEFAULT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.multicast_queue ALTER COLUMN id SET DEFAULT nextval('public.multicast_queue_id_seq'::regclass);


--
-- TOC entry 3562 (class 0 OID 17055)
-- Dependencies: 211
-- Data for Name: code_migration; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.code_migration (id, applied_at) FROM stdin;
migrate_to_cluster_keys	2026-10-06 13:32:31.322569+00
migrate_to_golang_migrate	2026-10-06 13:32:31.337465+00
\.


--
-- TOC entry 3563 (class 0 OID 17060)
-- Dependencies: 212
-- Data for Name: device; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.device (dev_eui, created_at, updated_at, device_profile_id, service_profile_id, routing_profile_id, skip_fcnt_check, reference_altitude, mode, is_disabled) FROM stdin;
\\x08fdbe4bc604e8f8	2026-05-17 14:44:05.64873+00	2026-11-11 20:49:27.070803+00	1ba78642-7e07-4f89-8dd9-4e2f7a025348	3dd33931-1cf7-4a56-8479-e88afa94a9e5	6d5db27e-4ce2-4b3b-b5d7-91f069397878	f	0	A	f
\\xf38df5e5a31e63de	2026-05-17 14:45:29.068031+00	2026-11-11 20:49:52.052894+00	014c944b-cfa0-472d-94df-fd6c18843572	3dd33931-1cf7-4a56-8479-e88afa94a9e5	6d5db27e-4ce2-4b3b-b5d7-91f069397878	f	0	 	f
\\x5f904b22e1ce458c	2026-11-09 20:36:18.611133+00	2026-11-11 20:50:19.595246+00	27b8058c-f0ac-41d5-b64a-46416260f6fd	3dd33931-1cf7-4a56-8479-e88afa94a9e5	6d5db27e-4ce2-4b3b-b5d7-91f069397878	f	0	A	f
\\x0379385c33313636	2026-11-09 20:37:38.843345+00	2026-11-11 20:50:32.360477+00	9ba1268a-1f93-44bd-b8f8-d8c445e687a3	3dd33931-1cf7-4a56-8479-e88afa94a9e5	6d5db27e-4ce2-4b3b-b5d7-91f069397878	f	0	 	f
\.


--
-- TOC entry 3564 (class 0 OID 17066)
-- Dependencies: 213
-- Data for Name: device_activation; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.device_activation (id, created_at, dev_eui, join_eui, dev_addr, f_nwk_s_int_key, s_nwk_s_int_key, nwk_s_enc_key, dev_nonce, join_req_type) FROM stdin;
\.


--
-- TOC entry 3566 (class 0 OID 17072)
-- Dependencies: 215
-- Data for Name: device_multicast_group; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.device_multicast_group (dev_eui, multicast_group_id, created_at) FROM stdin;
\.


--
-- TOC entry 3567 (class 0 OID 17077)
-- Dependencies: 216
-- Data for Name: device_profile; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.device_profile (created_at, updated_at, device_profile_id, supports_class_b, class_b_timeout, ping_slot_period, ping_slot_dr, ping_slot_freq, supports_class_c, class_c_timeout, mac_version, reg_params_revision, rx_delay_1, rx_dr_offset_1, rx_data_rate_2, rx_freq_2, factory_preset_freqs, max_eirp, max_duty_cycle, supports_join, rf_region, supports_32bit_fcnt, adr_algorithm_id) FROM stdin;
2026-05-01 19:43:58.139804+00	2026-11-09 21:36:26.506756+00	d39827e9-1e0c-4f90-94c3-04df5fe12a25	f	0	0	0	0	t	0	1.0.3	A	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-05-10 15:49:27.074432+00	2026-11-09 21:36:48.711239+00	dbace6c1-ee3b-4b64-a737-499589bcad82	f	0	0	0	0	t	0	1.0.3	A	0	0	0	0	\N	30	0	t	AU915	f	default
2026-05-01 19:45:40.618656+00	2026-11-09 21:37:06.711075+00	1cf78205-847a-46f3-acef-8f55842431c9	f	0	0	0	0	t	0	1.0.3	B	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-05-10 15:51:16.574469+00	2026-11-09 21:37:38.417287+00	47dbd59c-dbeb-4341-a0ee-78ac23caa698	f	0	0	0	0	t	0	1.0.3	B	0	0	0	0	\N	30	0	t	AU915	f	default
2026-05-01 19:44:53.824646+00	2026-11-09 21:38:02.221895+00	098744b6-72ba-494e-b276-2a5b831abde5	f	0	0	0	0	t	0	1.0.3	A	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-05-10 15:50:43.506122+00	2026-11-09 21:38:34.357166+00	edb8165c-2f2b-49ff-8dd9-448484c1f92a	f	0	0	0	0	t	0	1.0.3	A	0	0	0	0	\N	30	0	t	AU915	f	default
2026-05-01 19:46:21.938333+00	2026-11-09 21:39:07.841017+00	1ba78642-7e07-4f89-8dd9-4e2f7a025348	f	0	0	0	0	f	0	1.0.3	B	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-05-10 15:51:49.822952+00	2026-11-09 21:39:30.538238+00	014c944b-cfa0-472d-94df-fd6c18843572	f	0	0	0	0	f	0	1.0.3	B	0	0	0	0	\N	30	0	t	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	19bc5305-9df6-41a9-8579-d95b831dfe21	f	0	0	0	0	f	0	1.0.3	A	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	5fcc3bd5-ee0a-443a-bd36-dc8090c9c829	t	5	4096	8	0	f	0	1.0.3	A	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	ca190bd8-03d3-4de0-bbd1-55b17951aa3c	t	5	4096	8	0	t	0	1.0.3	A	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	d5a66c27-ef0c-40d7-830a-7fcb83dcdb6c	f	0	0	0	0	f	0	1.0.3	A	0	0	0	0	\N	30	0	t	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	95a463e5-a2df-4085-82fe-54de6cb1d049	t	5	4096	8	0	f	0	1.0.3	A	0	0	0	0	\N	30	0	t	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	f28cb0e4-c628-4e16-bb92-c2d8c1364a12	t	5	4096	8	0	t	0	1.0.3	A	0	0	0	0	\N	30	0	t	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	555168af-da8e-424d-b472-9870e1a5ed41	f	0	0	0	0	f	0	1.0.3	B	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	57df4655-4f5d-4910-b370-fbdeb8a8ec08	t	5	4096	8	0	f	0	1.0.3	B	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	104cd055-dccf-463e-93cb-c9ab654d8a05	t	5	4096	8	0	t	0	1.0.3	B	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	14d9d145-1a45-4c76-bb47-65475489723d	f	0	0	0	0	f	0	1.0.3	B	0	0	0	0	\N	30	0	t	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	96efa32d-213f-4ba8-97c5-ac68aad4dc7d	t	5	4096	8	0	f	0	1.0.3	B	0	0	0	0	\N	30	0	t	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	94517506-edf7-4004-b7c7-01ade05f1693	t	5	4096	8	0	t	0	1.0.3	B	0	0	0	0	\N	30	0	t	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	9b3b4663-0c02-4d9e-846a-478ff35bea4b	f	0	0	0	0	f	0	1.0.3	A	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	e9d4aa8d-1d25-420d-9fa2-f679f66b56f4	t	5	4096	8	0	f	0	1.0.3	A	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	3bdc845c-988a-4854-ae37-b0c360b88888	t	5	4096	8	0	t	0	1.0.3	A	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	0c74b73b-752d-4510-8cfe-eb42eb540610	f	0	0	0	0	f	0	1.0.3	A	0	0	0	0	\N	30	0	t	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	8f59ed88-43c4-4192-83a7-4b409d8819a4	t	5	4096	8	0	f	0	1.0.3	A	0	0	0	0	\N	30	0	t	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	a61d9cfc-0de7-40ce-bfab-343d8d580e1a	t	5	4096	8	0	t	0	1.0.3	A	0	0	0	0	\N	30	0	t	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	f71394cd-3746-40e5-867a-033706060da1	t	5	4096	8	0	f	0	1.0.3	B	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	27b8058c-f0ac-41d5-b64a-46416260f6fd	f	0	0	0	0	t	0	1.0.3	B	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	6fe77ac6-9b6b-4a3e-b6f1-bb1372df0b25	t	5	4096	8	0	t	0	1.0.3	B	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	ef0a5d73-937a-43f4-8135-5c8fd970d075	t	5	4096	8	0	f	0	1.0.3	B	0	0	0	0	\N	30	0	t	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	9ba1268a-1f93-44bd-b8f8-d8c445e687a3	f	0	0	0	0	t	0	1.0.3	B	0	0	0	0	\N	30	0	t	AU915	f	default
2026-11-11 20:14:04.792604+00	2026-11-11 20:14:04.792604+00	ce7b57bb-e483-4659-8df9-7ee3b00451f7	t	5	4096	8	0	t	0	1.0.3	B	0	0	0	0	\N	30	0	t	AU915	f	default
\.


--
-- TOC entry 3568 (class 0 OID 17082)
-- Dependencies: 217
-- Data for Name: device_queue; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.device_queue (id, created_at, updated_at, dev_eui, frm_payload, f_cnt, f_port, confirmed, is_pending, timeout_after, emit_at_time_since_gps_epoch, dev_addr, retry_after) FROM stdin;
\.


--
-- TOC entry 3570 (class 0 OID 17088)
-- Dependencies: 219
-- Data for Name: gateway; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.gateway (gateway_id, created_at, updated_at, first_seen_at, last_seen_at, location, altitude, gateway_profile_id, routing_profile_id, tls_cert, service_profile_id) FROM stdin;
\\xa840411b7dcc4150	2026-05-01 19:49:45.276535+00	2026-05-01 19:49:45.276535+00	\N	\N	(51.482594,-0.007661)	0	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	6d5db27e-4ce2-4b3b-b5d7-91f069397878	\\x	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\\xe45f01fffe10e12e	2026-05-01 19:49:17.46373+00	2026-11-09 20:26:52.39603+00	\N	\N	(51.482594,-0.007661)	0	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	6d5db27e-4ce2-4b3b-b5d7-91f069397878	\\x	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\\xb827ebfffea04db6	2026-05-01 19:47:14.933522+00	2026-11-09 20:27:03.783995+00	\N	\N	(51.482594,-0.007661)	0	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	6d5db27e-4ce2-4b3b-b5d7-91f069397878	\\x	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\\xb827ebfffe158993	2026-05-01 19:47:40.941562+00	2026-11-09 20:27:13.415187+00	\N	\N	(51.482594,-0.007661)	0	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	6d5db27e-4ce2-4b3b-b5d7-91f069397878	\\x	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\\xb827ebfffef81e69	2026-05-01 19:48:08.120986+00	2026-11-09 20:27:23.043714+00	\N	\N	(51.482594,-0.007661)	0	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	6d5db27e-4ce2-4b3b-b5d7-91f069397878	\\x	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\\xb827ebfffe78ffce	2026-05-01 19:48:38.204434+00	2026-11-09 20:27:31.728552+00	\N	\N	(51.482594,-0.007661)	0	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	6d5db27e-4ce2-4b3b-b5d7-91f069397878	\\x	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\\xa842e3fffe90a3d4	2026-11-09 20:34:16.197136+00	2026-11-09 20:34:16.197136+00	\N	\N	(-3.735552,-40.9894912)	0	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	6d5db27e-4ce2-4b3b-b5d7-91f069397878	\\x	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\\xa842e3fffe90a3d5	2026-11-09 20:34:54.73541+00	2026-11-09 20:34:54.73541+00	\N	\N	(-3.735552,-40.9894912)	0	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	6d5db27e-4ce2-4b3b-b5d7-91f069397878	\\x	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\.


--
-- TOC entry 3571 (class 0 OID 17093)
-- Dependencies: 220
-- Data for Name: gateway_board; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.gateway_board (id, gateway_id, fpga_id, fine_timestamp_key) FROM stdin;
\.


--
-- TOC entry 3572 (class 0 OID 17098)
-- Dependencies: 221
-- Data for Name: gateway_profile; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.gateway_profile (gateway_profile_id, created_at, updated_at, channels, stats_interval) FROM stdin;
2064912e-be4a-4dd2-9b7e-702ccff3dcb4	2026-05-01 19:41:01.788194+00	2026-05-01 19:41:01.788194+00	{8,9,10,11,12,13,14,15,65}	30000000000
544d2b2b-153c-4022-96c1-5f5aa8361361	2026-05-01 19:40:41.702142+00	2026-05-16 14:20:05.474999+00	{0,1,2,3,4,5,6,7,64}	30000000000
\.


--
-- TOC entry 3573 (class 0 OID 17103)
-- Dependencies: 222
-- Data for Name: gateway_profile_extra_channel; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.gateway_profile_extra_channel (id, gateway_profile_id, modulation, frequency, bandwidth, bitrate, spreading_factors) FROM stdin;
\.


--
-- TOC entry 3575 (class 0 OID 17109)
-- Dependencies: 224
-- Data for Name: multicast_group; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.multicast_group (id, created_at, updated_at, mc_addr, mc_nwk_s_key, f_cnt, group_type, dr, frequency, ping_slot_period, routing_profile_id, service_profile_id) FROM stdin;
\.


--
-- TOC entry 3576 (class 0 OID 17114)
-- Dependencies: 225
-- Data for Name: multicast_queue; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.multicast_queue (id, created_at, schedule_at, emit_at_time_since_gps_epoch, multicast_group_id, gateway_id, f_cnt, f_port, frm_payload, updated_at, retry_after) FROM stdin;
\.


--
-- TOC entry 3578 (class 0 OID 17120)
-- Dependencies: 227
-- Data for Name: routing_profile; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.routing_profile (created_at, updated_at, routing_profile_id, as_id, ca_cert, tls_cert, tls_key) FROM stdin;
2026-05-01 19:39:52.979384+00	2026-05-16 14:20:10.321638+00	6d5db27e-4ce2-4b3b-b5d7-91f069397878	chirpstack-v3-application-server-service.chirpstack-v3.svc.cluster.local:8001			
\.


--
-- TOC entry 3579 (class 0 OID 17128)
-- Dependencies: 228
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.schema_migrations (version, dirty) FROM stdin;
33	f
\.


--
-- TOC entry 3580 (class 0 OID 17131)
-- Dependencies: 229
-- Data for Name: service_profile; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.service_profile (created_at, updated_at, service_profile_id, ul_rate, ul_bucket_size, ul_rate_policy, dl_rate, dl_bucket_size, dl_rate_policy, add_gw_metadata, dev_status_req_freq, report_dev_status_battery, report_dev_status_margin, dr_min, dr_max, channel_mask, pr_allowed, hr_allowed, ra_allowed, nwk_geo_loc, target_per, min_gw_diversity, gws_private) FROM stdin;
2026-05-01 19:42:55.949253+00	2026-05-16 14:20:33.142145+00	3dd33931-1cf7-4a56-8479-e88afa94a9e5	0	0	Drop	0	0	Drop	t	916800000	t	t	0	5	\\x	f	f	f	t	0	0	f
\.


--
-- TOC entry 3592 (class 0 OID 0)
-- Dependencies: 214
-- Name: device_activation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: chirpstack_ns
--

SELECT pg_catalog.setval('public.device_activation_id_seq', 1, false);


--
-- TOC entry 3593 (class 0 OID 0)
-- Dependencies: 218
-- Name: device_queue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: chirpstack_ns
--

SELECT pg_catalog.setval('public.device_queue_id_seq', 1, false);


--
-- TOC entry 3594 (class 0 OID 0)
-- Dependencies: 223
-- Name: gateway_profile_extra_channel_id_seq; Type: SEQUENCE SET; Schema: public; Owner: chirpstack_ns
--

SELECT pg_catalog.setval('public.gateway_profile_extra_channel_id_seq', 1, false);


--
-- TOC entry 3595 (class 0 OID 0)
-- Dependencies: 226
-- Name: multicast_queue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: chirpstack_ns
--

SELECT pg_catalog.setval('public.multicast_queue_id_seq', 1, false);


--
-- TOC entry 3359 (class 2606 OID 17142)
-- Name: code_migration code_migration_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.code_migration
    ADD CONSTRAINT code_migration_pkey PRIMARY KEY (id);


--
-- TOC entry 3367 (class 2606 OID 17144)
-- Name: device_activation device_activation_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_activation
    ADD CONSTRAINT device_activation_pkey PRIMARY KEY (id);


--
-- TOC entry 3371 (class 2606 OID 17146)
-- Name: device_multicast_group device_multicast_group_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_multicast_group
    ADD CONSTRAINT device_multicast_group_pkey PRIMARY KEY (multicast_group_id, dev_eui);


--
-- TOC entry 3361 (class 2606 OID 17148)
-- Name: device device_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_pkey PRIMARY KEY (dev_eui);


--
-- TOC entry 3373 (class 2606 OID 17150)
-- Name: device_profile device_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_profile
    ADD CONSTRAINT device_profile_pkey PRIMARY KEY (device_profile_id);


--
-- TOC entry 3375 (class 2606 OID 17152)
-- Name: device_queue device_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_queue
    ADD CONSTRAINT device_queue_pkey PRIMARY KEY (id);


--
-- TOC entry 3386 (class 2606 OID 17154)
-- Name: gateway_board gateway_board_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway_board
    ADD CONSTRAINT gateway_board_pkey PRIMARY KEY (gateway_id, id);


--
-- TOC entry 3381 (class 2606 OID 17156)
-- Name: gateway gateway_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_pkey PRIMARY KEY (gateway_id);


--
-- TOC entry 3390 (class 2606 OID 17158)
-- Name: gateway_profile_extra_channel gateway_profile_extra_channel_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway_profile_extra_channel
    ADD CONSTRAINT gateway_profile_extra_channel_pkey PRIMARY KEY (id);


--
-- TOC entry 3388 (class 2606 OID 17160)
-- Name: gateway_profile gateway_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway_profile
    ADD CONSTRAINT gateway_profile_pkey PRIMARY KEY (gateway_profile_id);


--
-- TOC entry 3395 (class 2606 OID 17162)
-- Name: multicast_group multicast_group_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.multicast_group
    ADD CONSTRAINT multicast_group_pkey PRIMARY KEY (id);


--
-- TOC entry 3400 (class 2606 OID 17164)
-- Name: multicast_queue multicast_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.multicast_queue
    ADD CONSTRAINT multicast_queue_pkey PRIMARY KEY (id);


--
-- TOC entry 3402 (class 2606 OID 17166)
-- Name: routing_profile routing_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.routing_profile
    ADD CONSTRAINT routing_profile_pkey PRIMARY KEY (routing_profile_id);


--
-- TOC entry 3404 (class 2606 OID 17168)
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- TOC entry 3406 (class 2606 OID 17170)
-- Name: service_profile service_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.service_profile
    ADD CONSTRAINT service_profile_pkey PRIMARY KEY (service_profile_id);


--
-- TOC entry 3368 (class 1259 OID 17171)
-- Name: idx_device_activation_dev_eui; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_activation_dev_eui ON public.device_activation USING btree (dev_eui);


--
-- TOC entry 3369 (class 1259 OID 17172)
-- Name: idx_device_activation_nonce_lookup; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_activation_nonce_lookup ON public.device_activation USING btree (join_eui, dev_eui, join_req_type, dev_nonce);


--
-- TOC entry 3362 (class 1259 OID 17173)
-- Name: idx_device_device_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_device_profile_id ON public.device USING btree (device_profile_id);


--
-- TOC entry 3363 (class 1259 OID 17174)
-- Name: idx_device_mode; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_mode ON public.device USING btree (mode);


--
-- TOC entry 3376 (class 1259 OID 17175)
-- Name: idx_device_queue_confirmed; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_queue_confirmed ON public.device_queue USING btree (confirmed);


--
-- TOC entry 3377 (class 1259 OID 17176)
-- Name: idx_device_queue_dev_eui; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_queue_dev_eui ON public.device_queue USING btree (dev_eui);


--
-- TOC entry 3378 (class 1259 OID 17177)
-- Name: idx_device_queue_emit_at_time_since_gps_epoch; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_queue_emit_at_time_since_gps_epoch ON public.device_queue USING btree (emit_at_time_since_gps_epoch);


--
-- TOC entry 3379 (class 1259 OID 17178)
-- Name: idx_device_queue_timeout_after; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_queue_timeout_after ON public.device_queue USING btree (timeout_after);


--
-- TOC entry 3364 (class 1259 OID 17179)
-- Name: idx_device_routing_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_routing_profile_id ON public.device USING btree (routing_profile_id);


--
-- TOC entry 3365 (class 1259 OID 17180)
-- Name: idx_device_service_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_service_profile_id ON public.device USING btree (service_profile_id);


--
-- TOC entry 3382 (class 1259 OID 17181)
-- Name: idx_gateway_gateway_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_gateway_gateway_profile_id ON public.gateway USING btree (gateway_profile_id);


--
-- TOC entry 3391 (class 1259 OID 17182)
-- Name: idx_gateway_profile_extra_channel_gw_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_gateway_profile_extra_channel_gw_profile_id ON public.gateway_profile_extra_channel USING btree (gateway_profile_id);


--
-- TOC entry 3383 (class 1259 OID 17183)
-- Name: idx_gateway_routing_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_gateway_routing_profile_id ON public.gateway USING btree (routing_profile_id);


--
-- TOC entry 3384 (class 1259 OID 17184)
-- Name: idx_gateway_service_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_gateway_service_profile_id ON public.gateway USING btree (service_profile_id);


--
-- TOC entry 3392 (class 1259 OID 17185)
-- Name: idx_multicast_group_routing_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_multicast_group_routing_profile_id ON public.multicast_group USING btree (routing_profile_id);


--
-- TOC entry 3393 (class 1259 OID 17186)
-- Name: idx_multicast_group_service_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_multicast_group_service_profile_id ON public.multicast_group USING btree (service_profile_id);


--
-- TOC entry 3396 (class 1259 OID 17187)
-- Name: idx_multicast_queue_emit_at_time_since_gps_epoch; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_multicast_queue_emit_at_time_since_gps_epoch ON public.multicast_queue USING btree (emit_at_time_since_gps_epoch);


--
-- TOC entry 3397 (class 1259 OID 17188)
-- Name: idx_multicast_queue_multicast_group_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_multicast_queue_multicast_group_id ON public.multicast_queue USING btree (multicast_group_id);


--
-- TOC entry 3398 (class 1259 OID 17189)
-- Name: idx_multicast_queue_schedule_at; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_multicast_queue_schedule_at ON public.multicast_queue USING btree (schedule_at);


--
-- TOC entry 3410 (class 2606 OID 17190)
-- Name: device_activation device_activation_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_activation
    ADD CONSTRAINT device_activation_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3407 (class 2606 OID 17195)
-- Name: device device_device_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_device_profile_id_fkey FOREIGN KEY (device_profile_id) REFERENCES public.device_profile(device_profile_id) ON DELETE CASCADE;


--
-- TOC entry 3411 (class 2606 OID 17200)
-- Name: device_multicast_group device_multicast_group_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_multicast_group
    ADD CONSTRAINT device_multicast_group_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3412 (class 2606 OID 17205)
-- Name: device_multicast_group device_multicast_group_multicast_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_multicast_group
    ADD CONSTRAINT device_multicast_group_multicast_group_id_fkey FOREIGN KEY (multicast_group_id) REFERENCES public.multicast_group(id) ON DELETE CASCADE;


--
-- TOC entry 3413 (class 2606 OID 17210)
-- Name: device_queue device_queue_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_queue
    ADD CONSTRAINT device_queue_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3408 (class 2606 OID 17215)
-- Name: device device_routing_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_routing_profile_id_fkey FOREIGN KEY (routing_profile_id) REFERENCES public.routing_profile(routing_profile_id) ON DELETE CASCADE;


--
-- TOC entry 3409 (class 2606 OID 17220)
-- Name: device device_service_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_service_profile_id_fkey FOREIGN KEY (service_profile_id) REFERENCES public.service_profile(service_profile_id) ON DELETE CASCADE;


--
-- TOC entry 3417 (class 2606 OID 17225)
-- Name: gateway_board gateway_board_gateway_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway_board
    ADD CONSTRAINT gateway_board_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES public.gateway(gateway_id) ON DELETE CASCADE;


--
-- TOC entry 3414 (class 2606 OID 17230)
-- Name: gateway gateway_gateway_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_gateway_profile_id_fkey FOREIGN KEY (gateway_profile_id) REFERENCES public.gateway_profile(gateway_profile_id);


--
-- TOC entry 3418 (class 2606 OID 17235)
-- Name: gateway_profile_extra_channel gateway_profile_extra_channel_gateway_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway_profile_extra_channel
    ADD CONSTRAINT gateway_profile_extra_channel_gateway_profile_id_fkey FOREIGN KEY (gateway_profile_id) REFERENCES public.gateway_profile(gateway_profile_id) ON DELETE CASCADE;


--
-- TOC entry 3415 (class 2606 OID 17240)
-- Name: gateway gateway_routing_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_routing_profile_id_fkey FOREIGN KEY (routing_profile_id) REFERENCES public.routing_profile(routing_profile_id) ON DELETE CASCADE;


--
-- TOC entry 3416 (class 2606 OID 17245)
-- Name: gateway gateway_service_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_service_profile_id_fkey FOREIGN KEY (service_profile_id) REFERENCES public.service_profile(service_profile_id) ON DELETE CASCADE;


--
-- TOC entry 3419 (class 2606 OID 17250)
-- Name: multicast_group multicast_group_routing_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.multicast_group
    ADD CONSTRAINT multicast_group_routing_profile_id_fkey FOREIGN KEY (routing_profile_id) REFERENCES public.routing_profile(routing_profile_id) ON DELETE CASCADE;


--
-- TOC entry 3420 (class 2606 OID 17255)
-- Name: multicast_group multicast_group_service_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.multicast_group
    ADD CONSTRAINT multicast_group_service_profile_id_fkey FOREIGN KEY (service_profile_id) REFERENCES public.service_profile(service_profile_id) ON DELETE CASCADE;


--
-- TOC entry 3421 (class 2606 OID 17260)
-- Name: multicast_queue multicast_queue_gateway_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.multicast_queue
    ADD CONSTRAINT multicast_queue_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES public.gateway(gateway_id) ON DELETE CASCADE;


--
-- TOC entry 3422 (class 2606 OID 17265)
-- Name: multicast_queue multicast_queue_multicast_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.multicast_queue
    ADD CONSTRAINT multicast_queue_multicast_group_id_fkey FOREIGN KEY (multicast_group_id) REFERENCES public.multicast_group(id) ON DELETE CASCADE;


--
-- TOC entry 3587 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2026-11-11 18:28:54 -03

--
-- PostgreSQL database dump complete
--

\unrestrict razZQ3dpJ6NybUsHybFFb908HyEO1Uw1WEfegvV0cBf9tHfd1nDFJpuF4tEtOAk

