import { Dispatch } from './dispatch.service';

/** Builds a dispatch for tests. Override only the fields a test cares about. */
export function aDispatch(overrides: Partial<Dispatch> = {}): Dispatch {
  return {
    id: 1,
    reference: 'NWD-1001',
    status: 'InTransit',
    origin: 'Portland',
    destination: 'Seattle',
    driverName: 'Dana Ruiz',
    createdAt: '2026-08-03T09:00:00Z',
    eta: '2026-08-03T14:00:00Z',
    ...overrides,
  };
}

/** Types into an input the way a user does, firing the input event. */
export function typeInto(input: HTMLInputElement, value: string): void {
  input.value = value;
  input.dispatchEvent(new Event('input'));
}
