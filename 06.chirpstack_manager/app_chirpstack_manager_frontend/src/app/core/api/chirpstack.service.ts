import { HttpClient, HttpParams } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '@/environments/environment';
import {
    AdrAlgorithm,
    Aggregation,
    Application,
    ApplicationListItem,
    CertificateResponse,
    CsUser,
    CsUserListItem,
    Device,
    DeviceActivation,
    DeviceKeys,
    DeviceListItem,
    DeviceProfile,
    DeviceProfileDeviceListItem,
    DeviceProfileListItem,
    DeviceProfileVendorListItem,
    DeviceQueueItem,
    Gateway,
    GatewayListItem,
    GetApplicationResponse,
    GetCsUserResponse,
    GetDeviceActivationResponse,
    GetDeviceKeysResponse,
    GetDeviceLinkMetricsResponse,
    GetDeviceMetricsResponse,
    GetDeviceProfileByProfileIdResponse,
    GetDeviceProfileDeviceResponse,
    GetDeviceProfileResponse,
    GetDeviceProfileTemplateResponse,
    GetDeviceProfileVendorResponse,
    GetDeviceQueueItemsResponse,
    GetDeviceResponse,
    GetGatewayDutyCycleMetricsResponse,
    GetGatewayMetricsResponse,
    GetGatewayResponse,
    GetMulticastGroupResponse,
    GetRelayGatewayResponse,
    GetTenantResponse,
    GetTenantUserResponse,
    IdResponse,
    IntegrationListItem,
    ListResponse,
    MulticastGroup,
    MulticastGroupListItem,
    MulticastGroupQueueItem,
    RelayDeviceListItem,
    RelayGateway,
    RelayGatewayListItem,
    RelayListItem,
    Resumo,
    Tenant,
    TenantListItem,
    TenantUser,
    TenantUserListItem,
    UserTenant
} from './models';

export interface PageQuery {
    limit?: number;
    offset?: number;
    search?: string;
    /** Valores em lista viram o parâmetro repetido (ex.: tag=a=1&tag=b=2). */
    [key: string]: string | number | boolean | string[] | undefined | null;
}

/** Tipos de integração com formulário próprio (o nome é o mesmo do caminho da API). */
export type IntegrationPath = 'http' | 'influxdb' | 'thingsboard' | 'mydevices' | 'gcp-pub-sub' | 'aws-sns' | 'azure-service-bus' | 'pilot-things' | 'ifttt' | 'blynk';

/**
 * Acesso a todas as operações da REST API do ChirpStack v4.19, sempre através do backend
 * (que guarda a API key e aplica as permissões por perfil).
 */
@Injectable({ providedIn: 'root' })
export class ChirpstackService {
    private http = inject(HttpClient);
    private base = `${environment.apiUrl}/chirpstack`;

    private params(q?: PageQuery): HttpParams {
        let p = new HttpParams();
        if (q) {
            for (const [k, v] of Object.entries(q)) {
                if (Array.isArray(v)) {
                    for (const item of v) {
                        if (item !== '') {
                            p = p.append(k, item);
                        }
                    }
                } else if (v !== undefined && v !== null && v !== '') {
                    p = p.set(k, String(v));
                }
            }
        }
        return p;
    }

    private range(start: Date, end: Date, aggregation?: Aggregation): HttpParams {
        let p = new HttpParams().set('start', start.toISOString()).set('end', end.toISOString());
        if (aggregation) {
            p = p.set('aggregation', aggregation);
        }
        return p;
    }

    // ------------------------------------------------------------------ resumo

    resumo(tenantId: string): Observable<Resumo> {
        return this.http.get<Resumo>(`${this.base}/resumo`, { params: { tenantId } });
    }

    // ------------------------------------------------------------------ tenants

    listTenants(q?: PageQuery): Observable<ListResponse<TenantListItem>> {
        return this.http.get<ListResponse<TenantListItem>>(`${this.base}/tenants`, { params: this.params(q) });
    }
    getTenant(id: string): Observable<GetTenantResponse> {
        return this.http.get<GetTenantResponse>(`${this.base}/tenants/${id}`);
    }
    createTenant(tenant: Tenant): Observable<IdResponse> {
        return this.http.post<IdResponse>(`${this.base}/tenants`, { tenant });
    }
    updateTenant(id: string, tenant: Tenant): Observable<unknown> {
        return this.http.put(`${this.base}/tenants/${id}`, { tenant: { ...tenant, id } });
    }
    /** Tenants cujos prefixos de DevAddr se sobrepõem ao informado (4.19+). */
    listTenantsByDevAddrPrefixOverlap(devAddrPrefix: string): Observable<ListResponse<TenantListItem>> {
        return this.http.get<ListResponse<TenantListItem>>(`${this.base}/tenants/by-devaddr-prefix-overlap`, { params: { devAddrPrefix } });
    }
    deleteTenant(id: string): Observable<unknown> {
        return this.http.delete(`${this.base}/tenants/${id}`);
    }
    listTenantUsers(tenantId: string, q?: PageQuery): Observable<ListResponse<TenantUserListItem>> {
        return this.http.get<ListResponse<TenantUserListItem>>(`${this.base}/tenants/${tenantId}/users`, { params: this.params(q) });
    }
    getTenantUser(tenantId: string, userId: string): Observable<GetTenantUserResponse> {
        return this.http.get<GetTenantUserResponse>(`${this.base}/tenants/${tenantId}/users/${userId}`);
    }
    addTenantUser(tenantId: string, tenantUser: TenantUser): Observable<unknown> {
        return this.http.post(`${this.base}/tenants/${tenantId}/users`, { tenantUser: { ...tenantUser, tenantId } });
    }
    updateTenantUser(tenantId: string, userId: string, tenantUser: TenantUser): Observable<unknown> {
        return this.http.put(`${this.base}/tenants/${tenantId}/users/${userId}`, { tenantUser: { ...tenantUser, tenantId, userId } });
    }
    deleteTenantUser(tenantId: string, userId: string): Observable<unknown> {
        return this.http.delete(`${this.base}/tenants/${tenantId}/users/${userId}`);
    }

    // ------------------------------------------------------------------ users

    listUsers(q?: PageQuery): Observable<ListResponse<CsUserListItem>> {
        return this.http.get<ListResponse<CsUserListItem>>(`${this.base}/users`, { params: this.params(q) });
    }
    getUser(id: string): Observable<GetCsUserResponse> {
        return this.http.get<GetCsUserResponse>(`${this.base}/users/${id}`);
    }
    createUser(user: CsUser, password: string, tenants: UserTenant[]): Observable<IdResponse> {
        return this.http.post<IdResponse>(`${this.base}/users`, { user, password, tenants });
    }
    updateUser(id: string, user: CsUser): Observable<unknown> {
        return this.http.put(`${this.base}/users/${id}`, { user: { ...user, id } });
    }
    deleteUser(id: string): Observable<unknown> {
        return this.http.delete(`${this.base}/users/${id}`);
    }
    updateUserPassword(id: string, password: string): Observable<unknown> {
        return this.http.post(`${this.base}/users/${id}/password`, { userId: id, password });
    }

    // ------------------------------------------------------------------ applications

    listApplications(q: PageQuery): Observable<ListResponse<ApplicationListItem>> {
        return this.http.get<ListResponse<ApplicationListItem>>(`${this.base}/applications`, { params: this.params(q) });
    }
    getApplication(id: string): Observable<GetApplicationResponse> {
        return this.http.get<GetApplicationResponse>(`${this.base}/applications/${id}`);
    }
    createApplication(application: Application): Observable<IdResponse> {
        return this.http.post<IdResponse>(`${this.base}/applications`, { application });
    }
    updateApplication(id: string, application: Application): Observable<unknown> {
        return this.http.put(`${this.base}/applications/${id}`, { application: { ...application, id } });
    }
    deleteApplication(id: string): Observable<unknown> {
        return this.http.delete(`${this.base}/applications/${id}`);
    }
    listApplicationDeviceProfiles(id: string): Observable<{ result: { id: string; name: string }[] }> {
        return this.http.get<{ result: { id: string; name: string }[] }>(`${this.base}/applications/${id}/device-profiles`);
    }
    listApplicationDeviceTags(id: string): Observable<{ result: { key: string; values: string[] }[] }> {
        return this.http.get<{ result: { key: string; values: string[] }[] }>(`${this.base}/applications/${id}/device-tags`);
    }
    listIntegrations(id: string): Observable<ListResponse<IntegrationListItem>> {
        return this.http.get<ListResponse<IntegrationListItem>>(`${this.base}/applications/${id}/integrations`);
    }
    getIntegration<T = Record<string, unknown>>(id: string, tipo: IntegrationPath): Observable<{ integration: T }> {
        return this.http.get<{ integration: T }>(`${this.base}/applications/${id}/integrations/${tipo}`);
    }
    createIntegration(id: string, tipo: IntegrationPath, integration: Record<string, unknown>): Observable<unknown> {
        return this.http.post(`${this.base}/applications/${id}/integrations/${tipo}`, { integration: { ...integration, applicationId: id } });
    }
    updateIntegration(id: string, tipo: IntegrationPath, integration: Record<string, unknown>): Observable<unknown> {
        return this.http.put(`${this.base}/applications/${id}/integrations/${tipo}`, { integration: { ...integration, applicationId: id } });
    }
    deleteIntegration(id: string, tipo: IntegrationPath): Observable<unknown> {
        return this.http.delete(`${this.base}/applications/${id}/integrations/${tipo}`);
    }
    generateMqttCertificate(id: string): Observable<CertificateResponse> {
        return this.http.post<CertificateResponse>(`${this.base}/applications/${id}/integrations/mqtt/certificate`, {});
    }

    // ------------------------------------------------------------------ device profiles

    listDeviceProfiles(q: PageQuery): Observable<ListResponse<DeviceProfileListItem>> {
        return this.http.get<ListResponse<DeviceProfileListItem>>(`${this.base}/device-profiles`, { params: this.params(q) });
    }
    getDeviceProfile(id: string): Observable<GetDeviceProfileResponse> {
        return this.http.get<GetDeviceProfileResponse>(`${this.base}/device-profiles/${id}`);
    }
    createDeviceProfile(deviceProfile: DeviceProfile): Observable<IdResponse> {
        return this.http.post<IdResponse>(`${this.base}/device-profiles`, { deviceProfile });
    }
    updateDeviceProfile(id: string, deviceProfile: DeviceProfile): Observable<unknown> {
        return this.http.put(`${this.base}/device-profiles/${id}`, { deviceProfile: { ...deviceProfile, id } });
    }
    deleteDeviceProfile(id: string): Observable<unknown> {
        return this.http.delete(`${this.base}/device-profiles/${id}`);
    }
    listAdrAlgorithms(): Observable<ListResponse<AdrAlgorithm>> {
        return this.http.get<ListResponse<AdrAlgorithm>>(`${this.base}/device-profiles/adr-algorithms`);
    }
    /** Perfil pelo ProfileID do TR0005 (LoRa Alliance Vendor ID + Vendor Profile ID). */
    getDeviceProfileByVendorProfileId(vendorId: number, vendorProfileId: number): Observable<GetDeviceProfileByProfileIdResponse> {
        return this.http.get<GetDeviceProfileByProfileIdResponse>(`${this.base}/device-profiles/por-perfil-fabricante/${vendorId}/${vendorProfileId}`);
    }

    // ------------------------------------------------------------------ catálogo de dispositivos (4.19+)

    listDeviceProfileVendors(q?: PageQuery): Observable<ListResponse<DeviceProfileVendorListItem>> {
        return this.http.get<ListResponse<DeviceProfileVendorListItem>>(`${this.base}/device-profiles/vendors`, { params: this.params(q) });
    }
    getDeviceProfileVendor(id: string): Observable<GetDeviceProfileVendorResponse> {
        return this.http.get<GetDeviceProfileVendorResponse>(`${this.base}/device-profiles/vendors/${id}`);
    }
    deleteDeviceProfileVendor(id: string): Observable<unknown> {
        return this.http.delete(`${this.base}/device-profiles/vendors/${id}`);
    }
    listDeviceProfileDevices(vendorId?: string, q?: PageQuery): Observable<ListResponse<DeviceProfileDeviceListItem>> {
        return this.http.get<ListResponse<DeviceProfileDeviceListItem>>(`${this.base}/device-profiles/devices`, { params: this.params({ ...q, vendorId }) });
    }
    getDeviceProfileDevice(id: string): Observable<GetDeviceProfileDeviceResponse> {
        return this.http.get<GetDeviceProfileDeviceResponse>(`${this.base}/device-profiles/devices/${id}`);
    }
    deleteDeviceProfileDevice(id: string): Observable<unknown> {
        return this.http.delete(`${this.base}/device-profiles/devices/${id}`);
    }

    // ------------------------------------------------------------------ device profile templates

    listDeviceProfileTemplates(q?: PageQuery): Observable<ListResponse<DeviceProfileListItem>> {
        return this.http.get<ListResponse<DeviceProfileListItem>>(`${this.base}/device-profile-templates`, { params: this.params(q) });
    }
    getDeviceProfileTemplate(id: string): Observable<GetDeviceProfileTemplateResponse> {
        return this.http.get<GetDeviceProfileTemplateResponse>(`${this.base}/device-profile-templates/${encodeURIComponent(id)}`);
    }
    createDeviceProfileTemplate(deviceProfileTemplate: DeviceProfile): Observable<unknown> {
        return this.http.post(`${this.base}/device-profile-templates`, { deviceProfileTemplate });
    }
    updateDeviceProfileTemplate(id: string, deviceProfileTemplate: DeviceProfile): Observable<unknown> {
        return this.http.put(`${this.base}/device-profile-templates/${encodeURIComponent(id)}`, { deviceProfileTemplate: { ...deviceProfileTemplate, id } });
    }
    deleteDeviceProfileTemplate(id: string): Observable<unknown> {
        return this.http.delete(`${this.base}/device-profile-templates/${encodeURIComponent(id)}`);
    }

    // ------------------------------------------------------------------ devices

    listDevices(q: PageQuery): Observable<ListResponse<DeviceListItem>> {
        return this.http.get<ListResponse<DeviceListItem>>(`${this.base}/devices`, { params: this.params(q) });
    }
    getDevice(devEui: string): Observable<GetDeviceResponse> {
        return this.http.get<GetDeviceResponse>(`${this.base}/devices/${devEui}`);
    }
    createDevice(device: Device): Observable<unknown> {
        return this.http.post(`${this.base}/devices`, { device });
    }
    updateDevice(devEui: string, device: Device): Observable<unknown> {
        return this.http.put(`${this.base}/devices/${devEui}`, { device: { ...device, devEui } });
    }
    deleteDevice(devEui: string): Observable<unknown> {
        return this.http.delete(`${this.base}/devices/${devEui}`);
    }
    getDeviceKeys(devEui: string): Observable<GetDeviceKeysResponse> {
        return this.http.get<GetDeviceKeysResponse>(`${this.base}/devices/${devEui}/keys`);
    }
    createDeviceKeys(devEui: string, deviceKeys: DeviceKeys): Observable<unknown> {
        return this.http.post(`${this.base}/devices/${devEui}/keys`, { deviceKeys: { ...deviceKeys, devEui } });
    }
    updateDeviceKeys(devEui: string, deviceKeys: DeviceKeys): Observable<unknown> {
        return this.http.put(`${this.base}/devices/${devEui}/keys`, { deviceKeys: { ...deviceKeys, devEui } });
    }
    deleteDeviceKeys(devEui: string): Observable<unknown> {
        return this.http.delete(`${this.base}/devices/${devEui}/keys`);
    }
    flushDevNonces(devEui: string): Observable<unknown> {
        return this.http.delete(`${this.base}/devices/${devEui}/dev-nonces`);
    }
    getDeviceActivation(devEui: string): Observable<GetDeviceActivationResponse> {
        return this.http.get<GetDeviceActivationResponse>(`${this.base}/devices/${devEui}/activation`);
    }
    activateDevice(devEui: string, deviceActivation: DeviceActivation): Observable<unknown> {
        return this.http.post(`${this.base}/devices/${devEui}/activate`, { deviceActivation: { ...deviceActivation, devEui } });
    }
    deactivateDevice(devEui: string): Observable<unknown> {
        return this.http.delete(`${this.base}/devices/${devEui}/activation`);
    }
    getRandomDevAddr(devEui: string): Observable<{ devAddr: string }> {
        return this.http.post<{ devAddr: string }>(`${this.base}/devices/${devEui}/get-random-dev-addr`, {});
    }
    getNextFCntDown(devEui: string): Observable<{ fCntDown: number }> {
        return this.http.post<{ fCntDown: number }>(`${this.base}/devices/${devEui}/get-next-f-cnt-down`, {});
    }
    getDeviceQueue(devEui: string, countOnly = false): Observable<GetDeviceQueueItemsResponse> {
        return this.http.get<GetDeviceQueueItemsResponse>(`${this.base}/devices/${devEui}/queue`, { params: { countOnly } });
    }
    enqueue(devEui: string, queueItem: DeviceQueueItem, flushQueue = false): Observable<IdResponse> {
        return this.http.post<IdResponse>(`${this.base}/devices/${devEui}/queue`, { queueItem: { ...queueItem, devEui }, flushQueue });
    }
    flushDeviceQueue(devEui: string): Observable<unknown> {
        return this.http.delete(`${this.base}/devices/${devEui}/queue`);
    }
    getDeviceMetrics(devEui: string, start: Date, end: Date, aggregation: Aggregation): Observable<GetDeviceMetricsResponse> {
        return this.http.get<GetDeviceMetricsResponse>(`${this.base}/devices/${devEui}/metrics`, { params: this.range(start, end, aggregation) });
    }
    getDeviceLinkMetrics(devEui: string, start: Date, end: Date, aggregation: Aggregation): Observable<GetDeviceLinkMetricsResponse> {
        return this.http.get<GetDeviceLinkMetricsResponse>(`${this.base}/devices/${devEui}/link-metrics`, { params: this.range(start, end, aggregation) });
    }

    // ------------------------------------------------------------------ gateways

    listGateways(q: PageQuery): Observable<ListResponse<GatewayListItem>> {
        return this.http.get<ListResponse<GatewayListItem>>(`${this.base}/gateways`, { params: this.params(q) });
    }
    getGateway(id: string): Observable<GetGatewayResponse> {
        return this.http.get<GetGatewayResponse>(`${this.base}/gateways/${id}`);
    }
    createGateway(gateway: Gateway): Observable<unknown> {
        return this.http.post(`${this.base}/gateways`, { gateway });
    }
    updateGateway(id: string, gateway: Gateway): Observable<unknown> {
        return this.http.put(`${this.base}/gateways/${id}`, { gateway: { ...gateway, gatewayId: id } });
    }
    deleteGateway(id: string): Observable<unknown> {
        return this.http.delete(`${this.base}/gateways/${id}`);
    }
    getGatewayMetrics(id: string, start: Date, end: Date, aggregation: Aggregation): Observable<GetGatewayMetricsResponse> {
        return this.http.get<GetGatewayMetricsResponse>(`${this.base}/gateways/${id}/metrics`, { params: this.range(start, end, aggregation) });
    }
    getGatewayDutyCycleMetrics(id: string, start: Date, end: Date): Observable<GetGatewayDutyCycleMetricsResponse> {
        return this.http.get<GetGatewayDutyCycleMetricsResponse>(`${this.base}/gateways/${id}/duty-cycle-metrics`, { params: this.range(start, end) });
    }
    generateGatewayCertificate(id: string): Observable<CertificateResponse> {
        return this.http.post<CertificateResponse>(`${this.base}/gateways/${id}/generate-certificate`, {});
    }

    // ------------------------------------------------------------------ relay gateways

    listRelayGateways(q: PageQuery): Observable<ListResponse<RelayGatewayListItem>> {
        return this.http.get<ListResponse<RelayGatewayListItem>>(`${this.base}/gateways/relay-gateways`, { params: this.params(q) });
    }
    getRelayGateway(tenantId: string, relayId: string): Observable<GetRelayGatewayResponse> {
        return this.http.get<GetRelayGatewayResponse>(`${this.base}/gateways/relay-gateways/${tenantId}/${relayId}`);
    }
    updateRelayGateway(tenantId: string, relayId: string, relayGateway: RelayGateway): Observable<unknown> {
        return this.http.put(`${this.base}/gateways/relay-gateways/${tenantId}/${relayId}`, { relayGateway: { ...relayGateway, tenantId, relayId } });
    }
    deleteRelayGateway(tenantId: string, relayId: string): Observable<unknown> {
        return this.http.delete(`${this.base}/gateways/relay-gateways/${tenantId}/${relayId}`);
    }

    // ------------------------------------------------------------------ relays (TS011, 4.19+)

    listRelays(applicationId: string, q?: PageQuery): Observable<ListResponse<RelayListItem>> {
        return this.http.get<ListResponse<RelayListItem>>(`${this.base}/relays`, { params: this.params({ ...q, applicationId }) });
    }
    listRelayDevices(relayDevEui: string, q?: PageQuery): Observable<ListResponse<RelayDeviceListItem>> {
        return this.http.get<ListResponse<RelayDeviceListItem>>(`${this.base}/relays/${relayDevEui}/devices`, { params: this.params(q) });
    }
    addRelayDevice(relayDevEui: string, deviceDevEui: string): Observable<unknown> {
        return this.http.post(`${this.base}/relays/${relayDevEui}/devices`, { deviceDevEui });
    }
    removeRelayDevice(relayDevEui: string, deviceDevEui: string): Observable<unknown> {
        return this.http.delete(`${this.base}/relays/${relayDevEui}/devices/${deviceDevEui}`);
    }

    // ------------------------------------------------------------------ multicast groups

    listMulticastGroups(q: PageQuery): Observable<ListResponse<MulticastGroupListItem>> {
        return this.http.get<ListResponse<MulticastGroupListItem>>(`${this.base}/multicast-groups`, { params: this.params(q) });
    }
    getMulticastGroup(id: string): Observable<GetMulticastGroupResponse> {
        return this.http.get<GetMulticastGroupResponse>(`${this.base}/multicast-groups/${id}`);
    }
    createMulticastGroup(multicastGroup: MulticastGroup): Observable<IdResponse> {
        return this.http.post<IdResponse>(`${this.base}/multicast-groups`, { multicastGroup });
    }
    updateMulticastGroup(id: string, multicastGroup: MulticastGroup): Observable<unknown> {
        return this.http.put(`${this.base}/multicast-groups/${id}`, { multicastGroup: { ...multicastGroup, id } });
    }
    deleteMulticastGroup(id: string): Observable<unknown> {
        return this.http.delete(`${this.base}/multicast-groups/${id}`);
    }
    addMulticastDevice(id: string, devEui: string): Observable<unknown> {
        return this.http.post(`${this.base}/multicast-groups/${id}/devices`, { multicastGroupId: id, devEui });
    }
    removeMulticastDevice(id: string, devEui: string): Observable<unknown> {
        return this.http.delete(`${this.base}/multicast-groups/${id}/devices/${devEui}`);
    }
    addMulticastGateway(id: string, gatewayId: string): Observable<unknown> {
        return this.http.post(`${this.base}/multicast-groups/${id}/gateways`, { multicastGroupId: id, gatewayId });
    }
    removeMulticastGateway(id: string, gatewayId: string): Observable<unknown> {
        return this.http.delete(`${this.base}/multicast-groups/${id}/gateways/${gatewayId}`);
    }
    listMulticastQueue(id: string): Observable<{ items: MulticastGroupQueueItem[] }> {
        return this.http.get<{ items: MulticastGroupQueueItem[] }>(`${this.base}/multicast-groups/${id}/queue`);
    }
    enqueueMulticast(id: string, queueItem: MulticastGroupQueueItem): Observable<{ fCnt: number }> {
        return this.http.post<{ fCnt: number }>(`${this.base}/multicast-groups/${id}/queue`, { queueItem: { ...queueItem, multicastGroupId: id } });
    }
    flushMulticastQueue(id: string): Observable<unknown> {
        return this.http.delete(`${this.base}/multicast-groups/${id}/queue`);
    }
}
