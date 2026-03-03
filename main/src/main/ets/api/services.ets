import { request, RequestOptions } from './httpClient';
import type {
  UserBean, LoginRequest, SetUserinfoRequest, PetBean, UpdatePetsRequest, DelPetsRequest,
  FeedingSchedulesBean, AddFeedingDevicesRequest, UpdateFeedingDevicesRequest, DelFeedingDevicesRequest,
  AddFeedingSchedulesRequest, UpdateFeedingSchedulesRequest, DelFeedingSchedulesRequest,
  PetHealthHistory, GetPetHealthHistoryRequest, MonitoringBean, DataListBean,
  GetMonitoringRequest, GetFeedingRecordRequest, FeedingRecordBean, PutFeedingRequest
} from './types';

const BASE_URL = 'https://place.wxtcc.com.cn';

export interface BaseQueryParams {
  key: string;
  userId?: string;
  petId?: string;
}

// POST 用户登录
export async function petsUserLogin(params: LoginRequest): Promise<UserBean> {
  const options: RequestOptions = { method: 'POST', params: params as Object };
  return request<UserBean>(BASE_URL, '/officelease/pets/petsUserLogin', options);
}

// POST 设置用户信息
export async function setUserinfo(params: SetUserinfoRequest): Promise<string> {
  const options: RequestOptions = { method: 'POST', params: params as Object };
  return request<string>(BASE_URL, '/officelease/pets/setUserinfo', options);
}

// POST 查询用户信息 (新增)
export async function queryUser(params: Record<string, Object>): Promise<Object> {
  const options: RequestOptions = { method: 'POST', params: params as Object };
  return request<Object>(BASE_URL, '/officelease/pets/queryUser', options);
}

// GET 查看宠物
export async function getPets(key: string, userId: string = '1'): Promise<PetBean[]> {
  const p: BaseQueryParams = { key: key, userId: userId };
  const options: RequestOptions = { method: 'GET', params: p as Object };
  return request<PetBean[]>(BASE_URL, '/officelease/pets/getPets', options);
}

// GET 添加宠物信息 (新增)
export async function addPets(params: UpdatePetsRequest): Promise<string> {
  const options: RequestOptions = { method: 'GET', params: params as Object };
  return request<string>(BASE_URL, '/officelease/pets/addPets', options);
}

// GET 更新宠物信息
export async function updatePets(params: UpdatePetsRequest): Promise<string> {
  const options: RequestOptions = { method: 'GET', params: params as Object };
  return request<string>(BASE_URL, '/officelease/pets/updatePets', options);
}

// GET 删除宠物信息
export async function delPets(params: DelPetsRequest): Promise<string> {
  const options: RequestOptions = { method: 'GET', params: params as Object };
  return request<string>(BASE_URL, '/officelease/pets/delPets', options);
}

// GET 喂食计划
export async function getFeedingSchedules(key: string, petId: string): Promise<FeedingSchedulesBean[]> {
  const p: BaseQueryParams = { key: key, petId: petId };
  const options: RequestOptions = { method: 'GET', params: p as Object };
  return request<FeedingSchedulesBean[]>(BASE_URL, '/officelease/pets/feedingSchedules', options);
}

// GET 添加投喂计划
export async function addFeedingSchedules(params: AddFeedingSchedulesRequest): Promise<string> {
  const options: RequestOptions = { method: 'GET', params: params as Object };
  return request<string>(BASE_URL, '/officelease/pets/addFeedingSchedules', options);
}

// GET 修改喂食计划
export async function updateFeedingSchedules(params: UpdateFeedingSchedulesRequest): Promise<string> {
  const options: RequestOptions = { method: 'GET', params: params as Object };
  return request<string>(BASE_URL, '/officelease/pets/updateFeedingSchedules', options);
}

// GET 删除喂食计划
export async function delFeedingSchedules(params: DelFeedingSchedulesRequest): Promise<string> {
  const options: RequestOptions = { method: 'GET', params: params as Object };
  return request<string>(BASE_URL, '/officelease/pets/delFeedingSchedules', options);
}

// GET 查看设备记录 (新增)
export async function getFeedingDevices(key: string, userId: string): Promise<Object> {
  const p: BaseQueryParams = { key: key, userId: userId };
  const options: RequestOptions = { method: 'GET', params: p as Object };
  return request<Object>(BASE_URL, '/officelease/pets/feedingDevices', options);
}

// GET 添加设备
export async function addFeedingDevices(params: AddFeedingDevicesRequest): Promise<string> {
  const options: RequestOptions = { method: 'GET', params: params as Object };
  return request<string>(BASE_URL, '/officelease/pets/addfeedingDevices', options);
}

// GET 修改设备
export async function updateFeedingDevices(params: UpdateFeedingDevicesRequest): Promise<string> {
  const options: RequestOptions = { method: 'GET', params: params as Object };
  return request<string>(BASE_URL, '/officelease/pets/updatefeedingDevices', options);
}

// GET 删除设备
export async function delFeedingDevices(params: DelFeedingDevicesRequest): Promise<string> {
  const options: RequestOptions = { method: 'GET', params: params as Object };
  return request<string>(BASE_URL, '/officelease/pets/delfeedingDevices', options);
}

// POST 获取设备数据 (新增)
export async function getDeviceData(params: Record<string, Object>): Promise<Object> {
  const options: RequestOptions = { method: 'POST', params: params as Object };
  return request<Object>(BASE_URL, '/officelease/pets/getDeviceData', options);
}

// POST 下发设备命令 (新增)
export async function setDeviceCommands(params: Record<string, Object>): Promise<Object> {
  const options: RequestOptions = { method: 'POST', params: params as Object };
  return request<Object>(BASE_URL, '/officelease/pets/setDeviceCommands', options);
}

// GET 喂食记录
export async function getFeedingRecord(params: GetFeedingRecordRequest): Promise<DataListBean<FeedingRecordBean>> {
  const options: RequestOptions = { method: 'GET', params: params as Object };
  return request<DataListBean<FeedingRecordBean>>(BASE_URL, '/officelease/pets/getFeedingRecord', options);
}

// POST 远程喂食
export async function putFeeding(params: PutFeedingRequest): Promise<string> {
  const options: RequestOptions = { method: 'POST', params: params as Object };
  return request<string>(BASE_URL, '/officelease/pets/putFeeding', options);
}

// GET 查询宠物健康记录
export async function getPetHealthHistory(params: GetPetHealthHistoryRequest): Promise<DataListBean<PetHealthHistory>> {
  const options: RequestOptions = { method: 'GET', params: params as Object };
  return request<DataListBean<PetHealthHistory>>(BASE_URL, '/officelease/pets/getPetHealthHistory', options);
}

// GET 环境检测数据
export async function getMonitoring(params: GetMonitoringRequest): Promise<DataListBean<MonitoringBean>> {
  const options: RequestOptions = { method: 'GET', params: params as Object };
  return request<DataListBean<MonitoringBean>>(BASE_URL, '/officelease/pets/getMonitoring', options);
}