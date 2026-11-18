import { GoToken } from '../models/types';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api/v1';

export class ApiError extends Error {
  status: number;
  data: any;

  constructor(status: number, message: string, data?: any) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.data = data;
  }
}

class ApiClient {
  private baseUrl: string = API_BASE_URL;
  private accessToken: string | null = null;
  private refreshToken: string | null = null;
  private isRefreshing: boolean = false;
  private refreshSubscribers: Array<(token: string) => void> = [];
  private onUnauthorizedCallback?: () => void;

  constructor() {
    // Restore tokens from sessionStorage if available
    this.accessToken = sessionStorage.getItem('educca_access_token');
    this.refreshToken = sessionStorage.getItem('educca_refresh_token');
  }

  setTokens(accessToken: string, refreshToken: string) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    sessionStorage.setItem('educca_access_token', accessToken);
    sessionStorage.setItem('educca_refresh_token', refreshToken);
  }

  clearTokens() {
    this.accessToken = null;
    this.refreshToken = null;
    sessionStorage.removeItem('educca_access_token');
    sessionStorage.removeItem('educca_refresh_token');
  }

  getAccessToken(): string | null {
    return this.accessToken;
  }

  getRefreshToken(): string | null {
    return this.refreshToken;
  }

  setOnUnauthorized(callback: () => void) {
    this.onUnauthorizedCallback = callback;
  }

  private onTokenRefreshed(token: string) {
    this.refreshSubscribers.forEach(cb => cb(token));
    this.refreshSubscribers = [];
  }

  private addRefreshSubscriber(cb: (token: string) => void) {
    this.refreshSubscribers.push(cb);
  }

  async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const url = endpoint.startsWith('http') ? endpoint : `${this.baseUrl}${endpoint}`;

    const headers: Record<string, string> = {
      Accept: 'application/json',
      ...((options.headers as Record<string, string>) || {}),
    };

    if (this.accessToken && !headers['Authorization']) {
      headers['Authorization'] = `Bearer ${this.accessToken}`;
    }

    if (options.body && typeof options.body === 'string' && !headers['Content-Type']) {
      headers['Content-Type'] = 'application/json';
    }

    let response: Response;
    try {
      response = await fetch(url, {
        ...options,
        headers,
      });
    } catch (networkError: any) {
      throw new ApiError(0, `Error de conexión con el servidor (${networkError?.message || 'Servidor no disponible'})`);
    }

    // Handle 401 Unauthorized for token refresh
    if (response.status === 401 && this.refreshToken && !endpoint.includes('/login') && !endpoint.includes('/refresh')) {
      if (!this.isRefreshing) {
        this.isRefreshing = true;
        try {
          const newTokens = await this.doRefreshToken();
          this.setTokens(newTokens.access_token, newTokens.refresh_token);
          this.isRefreshing = false;
          this.onTokenRefreshed(newTokens.access_token);
          // Retry original request
          headers['Authorization'] = `Bearer ${newTokens.access_token}`;
          return this.request<T>(endpoint, { ...options, headers });
        } catch (refreshErr) {
          this.isRefreshing = false;
          this.clearTokens();
          if (this.onUnauthorizedCallback) {
            this.onUnauthorizedCallback();
          }
          throw new ApiError(401, 'Sesión expirada. Por favor inicie sesión nuevamente.');
        }
      } else {
        // Queue this request until refresh finishes
        return new Promise<T>((resolve, reject) => {
          this.addRefreshSubscriber((newToken: string) => {
            headers['Authorization'] = `Bearer ${newToken}`;
            this.request<T>(endpoint, { ...options, headers })
              .then(resolve)
              .catch(reject);
          });
        });
      }
    }

    // Process Response
    if (!response.ok) {
      let errorMessage = `Error HTTP ${response.status}: ${response.statusText}`;
      let errorData: any = null;
      try {
        const text = await response.text();
        if (text) {
          errorData = JSON.parse(text);
          errorMessage = errorData.error || errorData.message || errorMessage;
        }
      } catch {
        // Non-JSON error body
      }

      if (response.status === 401 && this.onUnauthorizedCallback && !this.refreshToken) {
        this.clearTokens();
        this.onUnauthorizedCallback();
      }

      throw new ApiError(response.status, errorMessage, errorData);
    }

    // 204 No Content or empty body
    if (response.status === 204) {
      return {} as T;
    }

    const contentType = response.headers.get('content-type');
    if (contentType && contentType.includes('application/json')) {
      const text = await response.text();
      return text ? (JSON.parse(text) as T) : ({} as T);
    }

    return (await response.text()) as unknown as T;
  }

  private async doRefreshToken(): Promise<GoToken> {
    const response = await fetch(`${this.baseUrl}/refresh`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({ refresh_token: this.refreshToken }),
    });

    if (!response.ok) {
      throw new Error('Refresh failed');
    }

    return response.json();
  }

  get<T>(endpoint: string, headers?: Record<string, string>): Promise<T> {
    return this.request<T>(endpoint, { method: 'GET', headers });
  }

  post<T>(endpoint: string, body?: any, headers?: Record<string, string>): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: body !== undefined ? JSON.stringify(body) : undefined,
      headers,
    });
  }

  put<T>(endpoint: string, body?: any, headers?: Record<string, string>): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'PUT',
      body: body !== undefined ? JSON.stringify(body) : undefined,
      headers,
    });
  }

  patch<T>(endpoint: string, body?: any, headers?: Record<string, string>): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'PATCH',
      body: body !== undefined ? JSON.stringify(body) : undefined,
      headers,
    });
  }

  delete<T>(endpoint: string, headers?: Record<string, string>): Promise<T> {
    return this.request<T>(endpoint, { method: 'DELETE', headers });
  }
}

export const apiClient = new ApiClient();
