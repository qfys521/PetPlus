// api/services.ts
import { request } from './httpClient';
import type {
  UserBean,
  LoginRequest,
  SetUserinfoRequest,
  PetBean,
  UpdatePetsRequest,
  FeedingSchedulesBean,
  AddFeedingDeviceRequest,
  PetHealthHistory,
  GetPetHealthHistoryRequest,
  MonitoringBean,
  DataListBean,
} from './types';

import { http } from '@kit.NetworkKit';

const BASE_URL = 'https://place.wxtcc.com.cn';

// ==================== 用户管理 API ====================
/**
 * 用户登录
 * @param params - 登录凭证
 * @returns 用户信息及认证密钥
 */
export async function petsUserLogin(params: LoginRequest): Promise<UserBean> {
  return request<UserBean>(
    BASE_URL,
    '/officelease/pets/petsUserLogin',
    {
      method: http.RequestMethod.POST,
      params: {
        userName: params.userName,
        psd: params.psd
      }
    }
  );
}

/**
 * 用户注册与信息设置
 * @param params - 用户信息
 * @returns 操作结果
 */
export async function setUserinfo(params: SetUserinfoRequest): Promise<string> {

  const queryParams: Record<string, string | number | boolean> = {
    userName: params.userName,
    password: params.password,
    type: params.type
  };

  // 有条件添加可选字段
  if (params.email) queryParams.email = params.email;
  if (params.phoneNumber) queryParams.phoneNumber = params.phoneNumber;
  if (params.homeAddress) queryParams.homeAddress = params.homeAddress;
  if (params.key) queryParams.key = params.key;

  return request<string>(
    BASE_URL,
    '/officelease/pets/setUserinfo',
    {
      method: http.RequestMethod.POST,
      params: queryParams
    }
  );
}

// ==================== 宠物档案 API ====================
/**
 * 获取宠物信息
 * @param key - 认证密钥
 * @param userId - 用户ID (系统硬编码为1)
 * @returns 宠物列表
 */
export async function getPets(key: string, userId: string = '1'): Promise<PetBean[]> {
  return request<PetBean[]>(
    BASE_URL,
    '/officelease/pets/getPets',
    {
      method: http.RequestMethod.GET,
      params: { key, userId }
    }
  );
}

/**
 * 更新宠物信息
 * @param params - 宠物更新数据
 * @returns 操作结果
 */
export async function updatePets(params: UpdatePetsRequest): Promise<string> {
  return request<string>(
    BASE_URL,
    '/officelease/pets/updatePets',
    {
      method: http.RequestMethod.POST,
      params: {
        key: params.key,
        petName: params.petName,
        petSpecies: params.petSpecies,
        petBreed: params.petBreed,
        petGender: params.petGender,
        birthDate: params.birthDate,
        currentweight: params.currentweight, // 注意字段名全小写
        healthstatus: params.healthstatus,   // 注意字段名全小写
        id: params.id,
        userId: params.userId
      }
    }
  );
}

// ==================== 喂养与健康 API ====================
/**
 * 获取喂食计划
 * @param key - 认证密钥
 * @param petId - 宠物ID
 * @returns 喂食计划列表
 */
export async function getFeedingSchedules(key: string, petId: string): Promise<FeedingSchedulesBean[]> {
  return request<FeedingSchedulesBean[]>(
    BASE_URL,
    '/officelease/pets/feedingSchedules',
    {
      method: http.RequestMethod.GET,
      params: { key, petId }
    }
  );
}

/**
 * 添加喂食设备
 * @param params - 喂食设备配置
 * @returns 操作结果
 */
export async function addFeedingDevices(params: AddFeedingDeviceRequest): Promise<string> {
  return request<string>(
    BASE_URL,
    '/officelease/pets/addFeedingDevices',
    {
      method: http.RequestMethod.POST,
      params: {
        key: params.key,
        petId: params.petId,
        deviceId: params.deviceId,
        scheduleTime: params.scheduleTime,
        foodAmount: params.foodAmount,
        isActive: params.isActive,
        scheduleIndo: params.scheduleIndo // 注意字段名拼写
      }
    }
  );
}

/**
 * 获取健康记录 (分页)
 * @param params - 查询参数
 * @returns 分页健康记录
 */
export async function getPetHealthHistory(
  params: GetPetHealthHistoryRequest
): Promise<DataListBean<PetHealthHistory>> {
  return request<DataListBean<PetHealthHistory>>(
    BASE_URL,
    '/officelease/pets/getPetHealthHistory',
    {
      method: http.RequestMethod.GET,
      params: {
        key: params.key,
        petId: params.petId,
        startTime: params.startTime,
        endTime: params.endTime,
        page: params.page,
        size: params.size
      }
    }
  );
}

// ==================== 仪表盘与监控 API ====================
/**
 * 获取环境监测数据
 * @param key - 认证密钥
 * @param userId - 用户ID
 * @returns 实时监测数据
 */
export async function getMonitoring(key: string, userId: string = '1'): Promise<MonitoringBean> {
  return request<MonitoringBean>(
    BASE_URL,
    '/officelease/pets/getMonitoring',
    {
      method: http.RequestMethod.GET,
      params: { key, userId }
    }
  );
}