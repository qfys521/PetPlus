import { request, RequestOptions } from './httpClient';
import type {
  UserBean, LoginRequest, SetUserinfoRequest, PetBean, UpdatePetsRequest,
  FeedingSchedulesBean, AddFeedingDeviceRequest, PetHealthHistory,
  GetPetHealthHistoryRequest, MonitoringBean, DataListBean,
  GetMonitoringRequest, GetFeedingRecordRequest, FeedingRecordBean, PutFeedingRequest
} from './types';

const BASE_URL = 'https://place.wxtcc.com.cn';


export interface BaseQueryParams {
  key: string;
  userId?: string;
  petId?: string;
}


export async function petsUserLogin(params: LoginRequest): Promise<UserBean> {
  const options: RequestOptions = { method: 'POST', params: params as Object };
  return request<UserBean>(BASE_URL, '/officelease/pets/petsUserLogin', options);
}

export async function setUserinfo(params: SetUserinfoRequest): Promise<string> {
  const options: RequestOptions = { method: 'POST', params: params as Object };
  return request<string>(BASE_URL, '/officelease/pets/setUserinfo', options);
}


export async function getPets(key: string, userId: string = '1'): Promise<PetBean[]> {
  const p: BaseQueryParams = { key: key, userId: userId };
  const options: RequestOptions = { method: 'GET', params: p as Object };
  return request<PetBean[]>(BASE_URL, '/officelease/pets/getPets', options);
}

export async function updatePets(params: UpdatePetsRequest): Promise<string> {
  const options: RequestOptions = { method: 'POST', params: params as Object };
  return request<string>(BASE_URL, '/officelease/pets/updatePets', options);
}


export async function getFeedingSchedules(key: string, petId: string): Promise<FeedingSchedulesBean[]> {
  const p: BaseQueryParams = { key: key, petId: petId };
  const options: RequestOptions = { method: 'GET', params: p as Object };
  return request<FeedingSchedulesBean[]>(BASE_URL, '/officelease/pets/feedingSchedules', options);
}

export async function addFeedingDevices(params: AddFeedingDeviceRequest): Promise<string> {
  const options: RequestOptions = { method: 'POST', params: params as Object };
  return request<string>(BASE_URL, '/officelease/pets/addFeedingDevices', options);
}


export async function getFeedingRecord(params: GetFeedingRecordRequest): Promise<DataListBean<FeedingRecordBean>> {
  const options: RequestOptions = { method: 'GET', params: params as Object };
  return request<DataListBean<FeedingRecordBean>>(BASE_URL, '/officelease/pets/getFeedingRecord', options);
}


export async function putFeeding(params: PutFeedingRequest): Promise<string> {
  const options: RequestOptions = { method: 'POST', params: params as Object };
  return request<string>(BASE_URL, '/officelease/pets/putFeeding', options);
}


export async function getPetHealthHistory(params: GetPetHealthHistoryRequest): Promise<DataListBean<PetHealthHistory>> {
  const options: RequestOptions = { method: 'GET', params: params as Object };
  return request<DataListBean<PetHealthHistory>>(BASE_URL, '/officelease/pets/getPetHealthHistory', options);
}

export async function getMonitoring(params: GetMonitoringRequest): Promise<DataListBean<MonitoringBean>> {
  const options: RequestOptions = { method: 'GET', params: params as Object };
  return request<DataListBean<MonitoringBean>>(BASE_URL, '/officelease/pets/getMonitoring', options);
}