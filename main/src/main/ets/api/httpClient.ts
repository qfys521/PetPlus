// api/httpClient.ts
import http from '@ohos.net.http';
import { ApiError, ResponseBean } from './types';

/**
 * 安全合并请求头（规避 arkts-no-spread）
 */
function mergeHeaders(custom?: Record<string, string>): Record<string, string> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  };

  if (custom) {
    const keys: string[] = Object.keys(custom);
    for (let i = 0; i < keys.length; i++) {
      const key: string = keys[i];
      headers[key] = custom[key];
    }
  }
  return headers;
}

/**
 * 构建查询参数（URL 编码）
 */
function buildQueryParams(params: Record<string, string | number | boolean>): string {
  const entries: string[] = [];
  const keys: string[] = Object.keys(params);

  for (let i = 0; i < keys.length; i++) {
    const key = keys[i];
    const value = params[key];

    // 空值跳过
    if (value === null || value === undefined) continue;

    // 特殊处理：布尔值转字符串
    let strValue = typeof value === 'boolean'
      ? (value ? 'true' : 'false')
      : String(value);

    // URL 编码（处理时间格式中的空格和冒号）
    strValue = encodeURIComponent(strValue)
      .replace(/%20/g, '+')
      .replace(/%3A/g, ':');

    entries.push(`${encodeURIComponent(key)}=${strValue}`);
  }
  return entries.join('&');
}

/**
 * 通用 HTTP 客户端（类型安全）
 */
export async function request<T>(
  baseUrl: string,
  endpoint: string,
  options: {
    method: http.RequestMethod;
    params?: Record<string, string | number | boolean>;
    data?: object;
    headers?: Record<string, string>;
    timeout?: number;
  }
): Promise<T> {

  const httpRequest = http.createHttp();

  try {
    let url = `${baseUrl}${endpoint}`;
    if (options.params && Object.keys(options.params).length > 0) {
      url += `?${buildQueryParams(options.params)}`;
    }

    const reqConfig: http.HttpRequestOptions = {
      method: options.method,
      header: mergeHeaders(options.headers),
      connectTimeout: options.timeout ?? 30000,
      readTimeout: options.timeout ?? 30000
    };

    if (
      options.data !== undefined &&
        (options.method === http.RequestMethod.POST ||
          options.method === http.RequestMethod.PUT)
    ) {
      reqConfig.extraData = JSON.stringify(options.data);
    }

    const response: http.HttpResponse =
      await httpRequest.request(url, reqConfig);

    if (response.responseCode < 200 || response.responseCode >= 300) {
      throw new ApiError(
        response.responseCode,
        `HTTP Error: ${response.responseCode}`
      );
    }

    const result = JSON.parse(response.result as string) as ResponseBean<T>;

    return result.data;

  } catch (err) {

    if (err instanceof ApiError) {
      throw err; // 保持 reject
    }

    throw new ApiError(-1, '网络异常或未知错误');

  } finally {
    httpRequest.destroy();
  }
}