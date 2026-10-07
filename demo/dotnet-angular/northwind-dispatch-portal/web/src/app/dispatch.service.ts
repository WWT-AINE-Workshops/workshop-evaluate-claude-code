import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

/** One dispatch as the API returns it (docs/api.md). */
export interface Dispatch {
  id: number;
  reference: string;
  status: string;
  origin: string;
  destination: string;
  driverName: string | null;
  createdAt: string;
  eta: string | null;
}

@Injectable({ providedIn: 'root' })
export class DispatchService {
  private readonly http = inject(HttpClient);

  list(status?: string, sort = 'created'): Observable<Dispatch[]> {
    let params = new HttpParams().set('sort', sort);
    if (status) {
      params = params.set('status', status);
    }
    return this.http.get<Dispatch[]>('/api/dispatches', { params });
  }

  search(query: string): Observable<Dispatch[]> {
    return this.http.get<Dispatch[]>('/api/dispatches/search', { params: { q: query } });
  }

  cancel(id: number): Observable<void> {
    return this.http.post<void>(`/api/dispatches/${id}/cancel`, null);
  }
}
