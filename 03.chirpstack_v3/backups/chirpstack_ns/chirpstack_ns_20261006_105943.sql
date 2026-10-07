--
-- PostgreSQL database dump
--

\restrict 0XtVtVTD91pBldX7NCaopAmMndPvrhPpaw1ttwEAfoX4P5cMSUiAeh0G17UNxaT

-- Dumped from database version 14.24
-- Dumped by pg_dump version 14.24

-- Started on 2026-10-06 13:59:48 UTC

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 209 (class 1259 OID 17055)
-- Name: code_migration; Type: TABLE; Schema: public; Owner: chirpstack_ns
--

CREATE TABLE public.code_migration (
    id text NOT NULL,
    applied_at timestamp with time zone NOT NULL
);


ALTER TABLE public.code_migration OWNER TO chirpstack_ns;

--
-- TOC entry 210 (class 1259 OID 17060)
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
-- TOC entry 211 (class 1259 OID 17066)
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
-- TOC entry 212 (class 1259 OID 17071)
-- Name: device_activation_id_seq; Type: SEQUENCE; Schema: public; Owner: chirpstack_ns
--

CREATE SEQUENCE public.device_activation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.device_activation_id_seq OWNER TO chirpstack_ns;

--
-- TOC entry 3584 (class 0 OID 0)
-- Dependencies: 212
-- Name: device_activation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chirpstack_ns
--

ALTER SEQUENCE public.device_activation_id_seq OWNED BY public.device_activation.id;


--
-- TOC entry 213 (class 1259 OID 17072)
-- Name: device_multicast_group; Type: TABLE; Schema: public; Owner: chirpstack_ns
--

CREATE TABLE public.device_multicast_group (
    dev_eui bytea NOT NULL,
    multicast_group_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.device_multicast_group OWNER TO chirpstack_ns;

--
-- TOC entry 214 (class 1259 OID 17077)
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
-- TOC entry 215 (class 1259 OID 17082)
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
-- TOC entry 216 (class 1259 OID 17087)
-- Name: device_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: chirpstack_ns
--

CREATE SEQUENCE public.device_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.device_queue_id_seq OWNER TO chirpstack_ns;

--
-- TOC entry 3585 (class 0 OID 0)
-- Dependencies: 216
-- Name: device_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chirpstack_ns
--

ALTER SEQUENCE public.device_queue_id_seq OWNED BY public.device_queue.id;


--
-- TOC entry 217 (class 1259 OID 17088)
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
-- TOC entry 218 (class 1259 OID 17093)
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
-- TOC entry 219 (class 1259 OID 17098)
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
-- TOC entry 220 (class 1259 OID 17103)
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
-- TOC entry 221 (class 1259 OID 17108)
-- Name: gateway_profile_extra_channel_id_seq; Type: SEQUENCE; Schema: public; Owner: chirpstack_ns
--

CREATE SEQUENCE public.gateway_profile_extra_channel_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.gateway_profile_extra_channel_id_seq OWNER TO chirpstack_ns;

--
-- TOC entry 3586 (class 0 OID 0)
-- Dependencies: 221
-- Name: gateway_profile_extra_channel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chirpstack_ns
--

ALTER SEQUENCE public.gateway_profile_extra_channel_id_seq OWNED BY public.gateway_profile_extra_channel.id;


--
-- TOC entry 222 (class 1259 OID 17109)
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
-- TOC entry 223 (class 1259 OID 17114)
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
-- TOC entry 224 (class 1259 OID 17119)
-- Name: multicast_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: chirpstack_ns
--

CREATE SEQUENCE public.multicast_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.multicast_queue_id_seq OWNER TO chirpstack_ns;

--
-- TOC entry 3587 (class 0 OID 0)
-- Dependencies: 224
-- Name: multicast_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: chirpstack_ns
--

ALTER SEQUENCE public.multicast_queue_id_seq OWNED BY public.multicast_queue.id;


--
-- TOC entry 225 (class 1259 OID 17120)
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
-- TOC entry 226 (class 1259 OID 17128)
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: chirpstack_ns
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    dirty boolean NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO chirpstack_ns;

--
-- TOC entry 227 (class 1259 OID 17131)
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
-- TOC entry 3348 (class 2604 OID 17137)
-- Name: device_activation id; Type: DEFAULT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_activation ALTER COLUMN id SET DEFAULT nextval('public.device_activation_id_seq'::regclass);


--
-- TOC entry 3349 (class 2604 OID 17138)
-- Name: device_queue id; Type: DEFAULT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_queue ALTER COLUMN id SET DEFAULT nextval('public.device_queue_id_seq'::regclass);


--
-- TOC entry 3350 (class 2604 OID 17139)
-- Name: gateway_profile_extra_channel id; Type: DEFAULT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway_profile_extra_channel ALTER COLUMN id SET DEFAULT nextval('public.gateway_profile_extra_channel_id_seq'::regclass);


--
-- TOC entry 3351 (class 2604 OID 17140)
-- Name: multicast_queue id; Type: DEFAULT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.multicast_queue ALTER COLUMN id SET DEFAULT nextval('public.multicast_queue_id_seq'::regclass);


--
-- TOC entry 3560 (class 0 OID 17055)
-- Dependencies: 209
-- Data for Name: code_migration; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.code_migration (id, applied_at) FROM stdin;
migrate_to_cluster_keys	2026-10-06 13:32:31.322569+00
migrate_to_golang_migrate	2026-10-06 13:32:31.337465+00
\.


--
-- TOC entry 3561 (class 0 OID 17060)
-- Dependencies: 210
-- Data for Name: device; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.device (dev_eui, created_at, updated_at, device_profile_id, service_profile_id, routing_profile_id, skip_fcnt_check, reference_altitude, mode, is_disabled) FROM stdin;
\\x08fdbe4bc604e8f8	2026-05-17 14:44:05.64873+00	2026-05-17 14:44:30.304817+00	1ba78642-7e07-4f89-8dd9-4e2f7a025348	3dd33931-1cf7-4a56-8479-e88afa94a9e5	6d5db27e-4ce2-4b3b-b5d7-91f069397878	f	0	A	f
\\xf38df5e5a31e63de	2026-05-17 14:45:29.068031+00	2026-05-17 14:45:29.068031+00	014c944b-cfa0-472d-94df-fd6c18843572	3dd33931-1cf7-4a56-8479-e88afa94a9e5	6d5db27e-4ce2-4b3b-b5d7-91f069397878	f	0	 	f
\.


--
-- TOC entry 3562 (class 0 OID 17066)
-- Dependencies: 211
-- Data for Name: device_activation; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.device_activation (id, created_at, dev_eui, join_eui, dev_addr, f_nwk_s_int_key, s_nwk_s_int_key, nwk_s_enc_key, dev_nonce, join_req_type) FROM stdin;
\.


--
-- TOC entry 3564 (class 0 OID 17072)
-- Dependencies: 213
-- Data for Name: device_multicast_group; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.device_multicast_group (dev_eui, multicast_group_id, created_at) FROM stdin;
\.


--
-- TOC entry 3565 (class 0 OID 17077)
-- Dependencies: 214
-- Data for Name: device_profile; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.device_profile (created_at, updated_at, device_profile_id, supports_class_b, class_b_timeout, ping_slot_period, ping_slot_dr, ping_slot_freq, supports_class_c, class_c_timeout, mac_version, reg_params_revision, rx_delay_1, rx_dr_offset_1, rx_data_rate_2, rx_freq_2, factory_preset_freqs, max_eirp, max_duty_cycle, supports_join, rf_region, supports_32bit_fcnt, adr_algorithm_id) FROM stdin;
2026-05-10 15:49:27.074432+00	2026-05-10 15:49:27.074432+00	dbace6c1-ee3b-4b64-a737-499589bcad82	f	0	0	0	0	t	5	1.0.3	A	0	0	0	0	\N	30	0	t	AU915	f	default
2026-05-10 15:50:43.506122+00	2026-05-10 15:50:43.506122+00	edb8165c-2f2b-49ff-8dd9-448484c1f92a	f	0	0	0	0	t	5	1.0.3	A	0	0	0	0	\N	30	0	t	AU915	f	default
2026-05-10 15:51:16.574469+00	2026-05-10 15:51:16.574469+00	47dbd59c-dbeb-4341-a0ee-78ac23caa698	f	0	0	0	0	t	5	1.0.3	B	0	0	0	0	\N	30	0	t	AU915	f	default
2026-05-01 19:43:58.139804+00	2026-05-11 18:40:21.617826+00	d39827e9-1e0c-4f90-94c3-04df5fe12a25	f	0	0	0	0	t	5	1.0.3	A	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-05-01 19:45:40.618656+00	2026-05-11 18:40:31.887282+00	1cf78205-847a-46f3-acef-8f55842431c9	f	0	0	0	0	t	5	1.0.3	B	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-05-01 19:44:53.824646+00	2026-05-11 18:40:49.86068+00	098744b6-72ba-494e-b276-2a5b831abde5	f	0	0	0	0	t	5	1.0.3	A	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-05-01 19:46:21.938333+00	2026-05-16 14:19:52.700534+00	1ba78642-7e07-4f89-8dd9-4e2f7a025348	f	0	0	0	0	f	5	1.0.3	B	1	0	8	923300000	{916800000}	30	0	f	AU915	f	default
2026-05-10 15:51:49.822952+00	2026-05-16 14:19:57.941032+00	014c944b-cfa0-472d-94df-fd6c18843572	f	0	0	0	0	f	5	1.0.3	B	0	0	0	0	\N	30	0	t	AU915	f	default
\.


--
-- TOC entry 3566 (class 0 OID 17082)
-- Dependencies: 215
-- Data for Name: device_queue; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.device_queue (id, created_at, updated_at, dev_eui, frm_payload, f_cnt, f_port, confirmed, is_pending, timeout_after, emit_at_time_since_gps_epoch, dev_addr, retry_after) FROM stdin;
\.


--
-- TOC entry 3568 (class 0 OID 17088)
-- Dependencies: 217
-- Data for Name: gateway; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.gateway (gateway_id, created_at, updated_at, first_seen_at, last_seen_at, location, altitude, gateway_profile_id, routing_profile_id, tls_cert, service_profile_id) FROM stdin;
\\xb827ebfffea04db6	2026-05-01 19:47:14.933522+00	2026-05-01 19:47:14.933522+00	\N	\N	(51.482594,-0.007661)	0	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	6d5db27e-4ce2-4b3b-b5d7-91f069397878	\\x	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\\xb827ebfffe158993	2026-05-01 19:47:40.941562+00	2026-05-01 19:47:40.941562+00	\N	\N	(51.482594,-0.007661)	0	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	6d5db27e-4ce2-4b3b-b5d7-91f069397878	\\x	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\\xb827ebfffef81e69	2026-05-01 19:48:08.120986+00	2026-05-01 19:48:08.120986+00	\N	\N	(51.482594,-0.007661)	0	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	6d5db27e-4ce2-4b3b-b5d7-91f069397878	\\x	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\\xb827ebfffe78ffce	2026-05-01 19:48:38.204434+00	2026-05-01 19:48:38.204434+00	\N	\N	(51.482594,-0.007661)	0	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	6d5db27e-4ce2-4b3b-b5d7-91f069397878	\\x	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\\xe45f01fffe10e12e	2026-05-01 19:49:17.46373+00	2026-05-01 19:49:17.46373+00	\N	\N	(51.482594,-0.007661)	0	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	6d5db27e-4ce2-4b3b-b5d7-91f069397878	\\x	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\\xa840411b7dcc4150	2026-05-01 19:49:45.276535+00	2026-05-01 19:49:45.276535+00	\N	\N	(51.482594,-0.007661)	0	2064912e-be4a-4dd2-9b7e-702ccff3dcb4	6d5db27e-4ce2-4b3b-b5d7-91f069397878	\\x	3dd33931-1cf7-4a56-8479-e88afa94a9e5
\.


--
-- TOC entry 3569 (class 0 OID 17093)
-- Dependencies: 218
-- Data for Name: gateway_board; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.gateway_board (id, gateway_id, fpga_id, fine_timestamp_key) FROM stdin;
\.


--
-- TOC entry 3570 (class 0 OID 17098)
-- Dependencies: 219
-- Data for Name: gateway_profile; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.gateway_profile (gateway_profile_id, created_at, updated_at, channels, stats_interval) FROM stdin;
2064912e-be4a-4dd2-9b7e-702ccff3dcb4	2026-05-01 19:41:01.788194+00	2026-05-01 19:41:01.788194+00	{8,9,10,11,12,13,14,15,65}	30000000000
544d2b2b-153c-4022-96c1-5f5aa8361361	2026-05-01 19:40:41.702142+00	2026-05-16 14:20:05.474999+00	{0,1,2,3,4,5,6,7,64}	30000000000
\.


--
-- TOC entry 3571 (class 0 OID 17103)
-- Dependencies: 220
-- Data for Name: gateway_profile_extra_channel; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.gateway_profile_extra_channel (id, gateway_profile_id, modulation, frequency, bandwidth, bitrate, spreading_factors) FROM stdin;
\.


--
-- TOC entry 3573 (class 0 OID 17109)
-- Dependencies: 222
-- Data for Name: multicast_group; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.multicast_group (id, created_at, updated_at, mc_addr, mc_nwk_s_key, f_cnt, group_type, dr, frequency, ping_slot_period, routing_profile_id, service_profile_id) FROM stdin;
\.


--
-- TOC entry 3574 (class 0 OID 17114)
-- Dependencies: 223
-- Data for Name: multicast_queue; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.multicast_queue (id, created_at, schedule_at, emit_at_time_since_gps_epoch, multicast_group_id, gateway_id, f_cnt, f_port, frm_payload, updated_at, retry_after) FROM stdin;
\.


--
-- TOC entry 3576 (class 0 OID 17120)
-- Dependencies: 225
-- Data for Name: routing_profile; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.routing_profile (created_at, updated_at, routing_profile_id, as_id, ca_cert, tls_cert, tls_key) FROM stdin;
2026-05-01 19:39:52.979384+00	2026-05-16 14:20:10.321638+00	6d5db27e-4ce2-4b3b-b5d7-91f069397878	chirpstack-v3-application-server-service.chirpstack-v3.svc.cluster.local:8001			
\.


--
-- TOC entry 3577 (class 0 OID 17128)
-- Dependencies: 226
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.schema_migrations (version, dirty) FROM stdin;
33	f
\.


--
-- TOC entry 3578 (class 0 OID 17131)
-- Dependencies: 227
-- Data for Name: service_profile; Type: TABLE DATA; Schema: public; Owner: chirpstack_ns
--

COPY public.service_profile (created_at, updated_at, service_profile_id, ul_rate, ul_bucket_size, ul_rate_policy, dl_rate, dl_bucket_size, dl_rate_policy, add_gw_metadata, dev_status_req_freq, report_dev_status_battery, report_dev_status_margin, dr_min, dr_max, channel_mask, pr_allowed, hr_allowed, ra_allowed, nwk_geo_loc, target_per, min_gw_diversity, gws_private) FROM stdin;
2026-05-01 19:42:55.949253+00	2026-05-16 14:20:33.142145+00	3dd33931-1cf7-4a56-8479-e88afa94a9e5	0	0	Drop	0	0	Drop	t	916800000	t	t	0	5	\\x	f	f	f	t	0	0	f
\.


--
-- TOC entry 3588 (class 0 OID 0)
-- Dependencies: 212
-- Name: device_activation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: chirpstack_ns
--

SELECT pg_catalog.setval('public.device_activation_id_seq', 1, false);


--
-- TOC entry 3589 (class 0 OID 0)
-- Dependencies: 216
-- Name: device_queue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: chirpstack_ns
--

SELECT pg_catalog.setval('public.device_queue_id_seq', 1, false);


--
-- TOC entry 3590 (class 0 OID 0)
-- Dependencies: 221
-- Name: gateway_profile_extra_channel_id_seq; Type: SEQUENCE SET; Schema: public; Owner: chirpstack_ns
--

SELECT pg_catalog.setval('public.gateway_profile_extra_channel_id_seq', 1, false);


--
-- TOC entry 3591 (class 0 OID 0)
-- Dependencies: 224
-- Name: multicast_queue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: chirpstack_ns
--

SELECT pg_catalog.setval('public.multicast_queue_id_seq', 1, false);


--
-- TOC entry 3357 (class 2606 OID 17142)
-- Name: code_migration code_migration_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.code_migration
    ADD CONSTRAINT code_migration_pkey PRIMARY KEY (id);


--
-- TOC entry 3365 (class 2606 OID 17144)
-- Name: device_activation device_activation_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_activation
    ADD CONSTRAINT device_activation_pkey PRIMARY KEY (id);


--
-- TOC entry 3369 (class 2606 OID 17146)
-- Name: device_multicast_group device_multicast_group_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_multicast_group
    ADD CONSTRAINT device_multicast_group_pkey PRIMARY KEY (multicast_group_id, dev_eui);


--
-- TOC entry 3359 (class 2606 OID 17148)
-- Name: device device_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_pkey PRIMARY KEY (dev_eui);


--
-- TOC entry 3371 (class 2606 OID 17150)
-- Name: device_profile device_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_profile
    ADD CONSTRAINT device_profile_pkey PRIMARY KEY (device_profile_id);


--
-- TOC entry 3373 (class 2606 OID 17152)
-- Name: device_queue device_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_queue
    ADD CONSTRAINT device_queue_pkey PRIMARY KEY (id);


--
-- TOC entry 3384 (class 2606 OID 17154)
-- Name: gateway_board gateway_board_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway_board
    ADD CONSTRAINT gateway_board_pkey PRIMARY KEY (gateway_id, id);


--
-- TOC entry 3379 (class 2606 OID 17156)
-- Name: gateway gateway_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_pkey PRIMARY KEY (gateway_id);


--
-- TOC entry 3388 (class 2606 OID 17158)
-- Name: gateway_profile_extra_channel gateway_profile_extra_channel_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway_profile_extra_channel
    ADD CONSTRAINT gateway_profile_extra_channel_pkey PRIMARY KEY (id);


--
-- TOC entry 3386 (class 2606 OID 17160)
-- Name: gateway_profile gateway_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway_profile
    ADD CONSTRAINT gateway_profile_pkey PRIMARY KEY (gateway_profile_id);


--
-- TOC entry 3393 (class 2606 OID 17162)
-- Name: multicast_group multicast_group_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.multicast_group
    ADD CONSTRAINT multicast_group_pkey PRIMARY KEY (id);


--
-- TOC entry 3398 (class 2606 OID 17164)
-- Name: multicast_queue multicast_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.multicast_queue
    ADD CONSTRAINT multicast_queue_pkey PRIMARY KEY (id);


--
-- TOC entry 3400 (class 2606 OID 17166)
-- Name: routing_profile routing_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.routing_profile
    ADD CONSTRAINT routing_profile_pkey PRIMARY KEY (routing_profile_id);


--
-- TOC entry 3402 (class 2606 OID 17168)
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- TOC entry 3404 (class 2606 OID 17170)
-- Name: service_profile service_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.service_profile
    ADD CONSTRAINT service_profile_pkey PRIMARY KEY (service_profile_id);


--
-- TOC entry 3366 (class 1259 OID 17171)
-- Name: idx_device_activation_dev_eui; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_activation_dev_eui ON public.device_activation USING btree (dev_eui);


--
-- TOC entry 3367 (class 1259 OID 17172)
-- Name: idx_device_activation_nonce_lookup; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_activation_nonce_lookup ON public.device_activation USING btree (join_eui, dev_eui, join_req_type, dev_nonce);


--
-- TOC entry 3360 (class 1259 OID 17173)
-- Name: idx_device_device_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_device_profile_id ON public.device USING btree (device_profile_id);


--
-- TOC entry 3361 (class 1259 OID 17174)
-- Name: idx_device_mode; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_mode ON public.device USING btree (mode);


--
-- TOC entry 3374 (class 1259 OID 17175)
-- Name: idx_device_queue_confirmed; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_queue_confirmed ON public.device_queue USING btree (confirmed);


--
-- TOC entry 3375 (class 1259 OID 17176)
-- Name: idx_device_queue_dev_eui; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_queue_dev_eui ON public.device_queue USING btree (dev_eui);


--
-- TOC entry 3376 (class 1259 OID 17177)
-- Name: idx_device_queue_emit_at_time_since_gps_epoch; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_queue_emit_at_time_since_gps_epoch ON public.device_queue USING btree (emit_at_time_since_gps_epoch);


--
-- TOC entry 3377 (class 1259 OID 17178)
-- Name: idx_device_queue_timeout_after; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_queue_timeout_after ON public.device_queue USING btree (timeout_after);


--
-- TOC entry 3362 (class 1259 OID 17179)
-- Name: idx_device_routing_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_routing_profile_id ON public.device USING btree (routing_profile_id);


--
-- TOC entry 3363 (class 1259 OID 17180)
-- Name: idx_device_service_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_device_service_profile_id ON public.device USING btree (service_profile_id);


--
-- TOC entry 3380 (class 1259 OID 17181)
-- Name: idx_gateway_gateway_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_gateway_gateway_profile_id ON public.gateway USING btree (gateway_profile_id);


--
-- TOC entry 3389 (class 1259 OID 17182)
-- Name: idx_gateway_profile_extra_channel_gw_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_gateway_profile_extra_channel_gw_profile_id ON public.gateway_profile_extra_channel USING btree (gateway_profile_id);


--
-- TOC entry 3381 (class 1259 OID 17183)
-- Name: idx_gateway_routing_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_gateway_routing_profile_id ON public.gateway USING btree (routing_profile_id);


--
-- TOC entry 3382 (class 1259 OID 17184)
-- Name: idx_gateway_service_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_gateway_service_profile_id ON public.gateway USING btree (service_profile_id);


--
-- TOC entry 3390 (class 1259 OID 17185)
-- Name: idx_multicast_group_routing_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_multicast_group_routing_profile_id ON public.multicast_group USING btree (routing_profile_id);


--
-- TOC entry 3391 (class 1259 OID 17186)
-- Name: idx_multicast_group_service_profile_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_multicast_group_service_profile_id ON public.multicast_group USING btree (service_profile_id);


--
-- TOC entry 3394 (class 1259 OID 17187)
-- Name: idx_multicast_queue_emit_at_time_since_gps_epoch; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_multicast_queue_emit_at_time_since_gps_epoch ON public.multicast_queue USING btree (emit_at_time_since_gps_epoch);


--
-- TOC entry 3395 (class 1259 OID 17188)
-- Name: idx_multicast_queue_multicast_group_id; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_multicast_queue_multicast_group_id ON public.multicast_queue USING btree (multicast_group_id);


--
-- TOC entry 3396 (class 1259 OID 17189)
-- Name: idx_multicast_queue_schedule_at; Type: INDEX; Schema: public; Owner: chirpstack_ns
--

CREATE INDEX idx_multicast_queue_schedule_at ON public.multicast_queue USING btree (schedule_at);


--
-- TOC entry 3408 (class 2606 OID 17190)
-- Name: device_activation device_activation_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_activation
    ADD CONSTRAINT device_activation_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3405 (class 2606 OID 17195)
-- Name: device device_device_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_device_profile_id_fkey FOREIGN KEY (device_profile_id) REFERENCES public.device_profile(device_profile_id) ON DELETE CASCADE;


--
-- TOC entry 3409 (class 2606 OID 17200)
-- Name: device_multicast_group device_multicast_group_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_multicast_group
    ADD CONSTRAINT device_multicast_group_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3410 (class 2606 OID 17205)
-- Name: device_multicast_group device_multicast_group_multicast_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_multicast_group
    ADD CONSTRAINT device_multicast_group_multicast_group_id_fkey FOREIGN KEY (multicast_group_id) REFERENCES public.multicast_group(id) ON DELETE CASCADE;


--
-- TOC entry 3411 (class 2606 OID 17210)
-- Name: device_queue device_queue_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device_queue
    ADD CONSTRAINT device_queue_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- TOC entry 3406 (class 2606 OID 17215)
-- Name: device device_routing_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_routing_profile_id_fkey FOREIGN KEY (routing_profile_id) REFERENCES public.routing_profile(routing_profile_id) ON DELETE CASCADE;


--
-- TOC entry 3407 (class 2606 OID 17220)
-- Name: device device_service_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_service_profile_id_fkey FOREIGN KEY (service_profile_id) REFERENCES public.service_profile(service_profile_id) ON DELETE CASCADE;


--
-- TOC entry 3415 (class 2606 OID 17225)
-- Name: gateway_board gateway_board_gateway_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway_board
    ADD CONSTRAINT gateway_board_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES public.gateway(gateway_id) ON DELETE CASCADE;


--
-- TOC entry 3412 (class 2606 OID 17230)
-- Name: gateway gateway_gateway_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_gateway_profile_id_fkey FOREIGN KEY (gateway_profile_id) REFERENCES public.gateway_profile(gateway_profile_id);


--
-- TOC entry 3416 (class 2606 OID 17235)
-- Name: gateway_profile_extra_channel gateway_profile_extra_channel_gateway_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway_profile_extra_channel
    ADD CONSTRAINT gateway_profile_extra_channel_gateway_profile_id_fkey FOREIGN KEY (gateway_profile_id) REFERENCES public.gateway_profile(gateway_profile_id) ON DELETE CASCADE;


--
-- TOC entry 3413 (class 2606 OID 17240)
-- Name: gateway gateway_routing_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_routing_profile_id_fkey FOREIGN KEY (routing_profile_id) REFERENCES public.routing_profile(routing_profile_id) ON DELETE CASCADE;


--
-- TOC entry 3414 (class 2606 OID 17245)
-- Name: gateway gateway_service_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_service_profile_id_fkey FOREIGN KEY (service_profile_id) REFERENCES public.service_profile(service_profile_id) ON DELETE CASCADE;


--
-- TOC entry 3417 (class 2606 OID 17250)
-- Name: multicast_group multicast_group_routing_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.multicast_group
    ADD CONSTRAINT multicast_group_routing_profile_id_fkey FOREIGN KEY (routing_profile_id) REFERENCES public.routing_profile(routing_profile_id) ON DELETE CASCADE;


--
-- TOC entry 3418 (class 2606 OID 17255)
-- Name: multicast_group multicast_group_service_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.multicast_group
    ADD CONSTRAINT multicast_group_service_profile_id_fkey FOREIGN KEY (service_profile_id) REFERENCES public.service_profile(service_profile_id) ON DELETE CASCADE;


--
-- TOC entry 3419 (class 2606 OID 17260)
-- Name: multicast_queue multicast_queue_gateway_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.multicast_queue
    ADD CONSTRAINT multicast_queue_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES public.gateway(gateway_id) ON DELETE CASCADE;


--
-- TOC entry 3420 (class 2606 OID 17265)
-- Name: multicast_queue multicast_queue_multicast_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack_ns
--

ALTER TABLE ONLY public.multicast_queue
    ADD CONSTRAINT multicast_queue_multicast_group_id_fkey FOREIGN KEY (multicast_group_id) REFERENCES public.multicast_group(id) ON DELETE CASCADE;


-- Completed on 2026-10-06 13:59:48 UTC

--
-- PostgreSQL database dump complete
--

\unrestrict 0XtVtVTD91pBldX7NCaopAmMndPvrhPpaw1ttwEAfoX4P5cMSUiAeh0G17UNxaT

