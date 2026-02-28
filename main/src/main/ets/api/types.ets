
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

export class ApiError extends Error {
  public code: number;
  public timestamp: string;

  constructor(code: number, message: string) {
    super(message);
    this.name = 'ApiError';
    this.code = code;
    this.timestamp = new Date().toISOString();
  }
}


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
  psd: string;
}

export interface SetUserinfoRequest {
  userName: string;
  email?: string;
  phoneNumber?: string;
  homeAddress?: string;
  password: string;
  type: '0' | '1';
  key?: string;
}


export interface PetBean {
  id: number;
  userId: number;
  petName: string;
  petSpecies: string;
  petBreed: string;
  petGender: string;
  birthDate: string;
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
  currentweight: string;
  healthstatus: string;
  id: string;
  userId: string;
}


export interface FeedingSchedulesBean {
  id: string;
  petId: string;
  deviceId: string;
  scheduleTime: string;
  foodAmount: string;
  isActive: boolean | string;
  createdAt: string;
  updatedAt: string;
  petName: string;
  petBreed: string;
  deviceName: string;
}

export interface AddFeedingDeviceRequest {
  key: string;
  petId: string;
  deviceId: string;
  scheduleTime: string;
  foodAmount: string;
  isActive: string;
  schedulesInfo: string;
}


export interface PetHealthHistory {
  petName?: string;
  petBreed?: string;
  recordId?: string;
  petId?: string;
  recordDate?: string;
  bodyWeight?: string;
  bodyTemperature?: string;
  heartRate?: string;
  respiratoryRate?: string;
  appetiteLevel?: string;
  energyLevel?: string;
  vaccinationStatus?: string;
  lastVaccinationDate?: string;
  dewormingStatus?: string;
  lastDewormingDate?: string;
  medicationList?: string;
  observedSymptoms?: string;
  vetNotes?: string;
  nextCheckupDate?: string;
  createdAt?: string;
  creatTime?: string;
}

export interface GetPetHealthHistoryRequest {
  key: string;
  petId: string;
  startTime: string;
  endTime: string;
  page: string;
  size: string;
}


export interface MonitoringBean {
  userId?: string;
  monitoringTime?: string;
  temperature?: string;
  humidity?: string;
  pm25?: string;
  co2?: string;
  tvoc?: string;
  noiseLevel?: string;
  lightIntensity?: string;
  airQuality?: string;
}

export interface GetMonitoringRequest {
  key: string;
  userId: string;
  page: string;
  size: string;
  startTime: string;
  endTime: string;
}


export interface FeedingRecordBean {
  scheduledTime?: string;
  actualTime?: string;
  plannedAmount?: string;
  actualAmount?: string;
  feedStatus?: string;
  feedNotes?: string;
  petBreed?: string;
  petName?: string;
  deviceName?: string;
}


export interface GetFeedingRecordRequest {
  key: string;
  petId: string;
  startTime: string;
  endTime: string;
  page: string;
  size: string;
}


export interface PutFeedingRequest {
  key: string;
  petId: string;
  plannedAmount: string;
  deviceId: string;
}