// api/types.ts
// ==================== 通用类型定义 ====================
export interface ResponseBean<T> {
  code: string;
  message: string;
  data: T;
  timestamp?: string;
  executeTime?: string;
}

export interface DataListBean<T> {
  total: number;
  list: T[];
}

export class ApiError {
  readonly name = 'ApiError';
  readonly code: number;
  readonly message: string;
  readonly timestamp: string;

  constructor(code: number, message: string) {
    this.code = code;
    this.message = message;
    this.timestamp = new Date().toISOString();
  }
}

// ==================== 用户管理类型 ====================
export interface UserBean {
  id: string;
  userName: string;
  email: string;
  phoneNumber: string;
  homeAddress: string;
  key: string;
}

export interface LoginRequest {
  userName: string;
  psd: string; // 注意字段名是 psd 而非 password
}

export interface SetUserinfoRequest {
  userName: string;
  email?: string;
  phoneNumber?: string;
  homeAddress?: string;
  password: string;
  type: '0' | '1'; // 0=注册, 1=修改
  key?: string; // type=1 时必填
}

// ==================== 宠物档案类型 ====================
export interface PetBean {
  id: number;
  userId: number;
  petName: string;
  petSpecies: string; // 种类（狗/猫）
  petBreed: string;  // 品种
  petGender: 'male' | 'female';
  birthDate: string; // ISO 8601
  currentWeight: number;
  healthStatus: string;
  createdAt: string;
  updatedAt: string;
}

export interface UpdatePetsRequest {
  key: string;
  petName: string;
  petSpecies: string;
  petBreed: string;
  petGender: string;
  birthDate: string;
  currentweight: string; // 注意字段名全小写 (服务端要求)
  healthstatus: string;  // 注意字段名全小写 (服务端要求)
  id: string;
  userId: string;
}

// ==================== 喂养与健康类型 ====================
export interface FeedingSchedulesBean {
  id: string;
  petId: string;
  deviceId: string;
  scheduleTime: string; // HH:mm:ss
  foodAmount: string;
  isActive: string; // "true"/"false"
  createdAt: string;
  updatedAt: string;
  petName: string;
  petBreed: string;
  deviceName: string;
}

export interface AddFeedingDeviceRequest {
  key: string;
  petId: string;
  deviceId: string; // 固定为 "1"
  scheduleTime: string; // HH:mm:ss
  foodAmount: string;   // 克
  isActive: string;     // "true"/"false"
  scheduleIndo: string; // 注意字段名拼写 (服务端要求)
}

export interface PetHealthHistory {
  petName: string;
  petBreed: string;
  recordDate: string;
  bodyWeight: string;       // kg
  bodyTemperature: string;  // ℃
  heartRate: string;        // bpm
  appetiteLevel: 'Excellent' | 'Normal' | 'Poor';
  energyLevel: 'High' | 'Normal' | 'Low';
  vaccinationStatus: 'Up-to-date' | 'Overdue';
  dewormingStatus: 'Completed' | 'Pending';
  vetNotes: string;
}

export interface GetPetHealthHistoryRequest {
  key: string;
  petId: string;
  startTime: string; // YYYY-MM-DD HH:mm
  endTime: string;   // YYYY-MM-DD HH:mm
  page: string;
  size: string;
}

// ==================== 仪表盘监控类型 ====================
export interface MonitoringBean {
  userId: string;
  monitoringTime: string;
  temperature: string;     // ℃
  humidity: string;        // %
  pm25: string;            // μg/m³
  co2: string;             // ppm
  tvoc: string;            // mg/m³
  noiseLevel: string;      // dB
  lightIntensity: string;  // lux
  airQuality: 'Good' | 'Moderate' | 'Poor';
}