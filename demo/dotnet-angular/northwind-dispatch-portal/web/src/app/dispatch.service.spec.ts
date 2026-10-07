import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { DispatchService } from './dispatch.service';
import { aDispatch } from './testing';

describe('DispatchService', () => {
  let service: DispatchService;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [provideHttpClient(), provideHttpClientTesting()] });
    service = TestBed.inject(DispatchService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('searches by query', () => {
    let result: unknown;
    service.search('NWD').subscribe((dispatches) => (result = dispatches));

    http.expectOne('/api/dispatches/search?q=NWD').flush([aDispatch()]);

    expect(result).toEqual([aDispatch()]);
  });

  it('lists with sort and an optional status', () => {
    service.list().subscribe();
    service.list('Pending', 'eta').subscribe();

    http.expectOne('/api/dispatches?sort=created').flush([]);
    http.expectOne('/api/dispatches?sort=eta&status=Pending').flush([]);
  });

  it('cancels with a POST', () => {
    service.cancel(3).subscribe();

    const request = http.expectOne('/api/dispatches/3/cancel');
    expect(request.request.method).toBe('POST');
    request.flush(null, { status: 204, statusText: 'No Content' });
  });
});
