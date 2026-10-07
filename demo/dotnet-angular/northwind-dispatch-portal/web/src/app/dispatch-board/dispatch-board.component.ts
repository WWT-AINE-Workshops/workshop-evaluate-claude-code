import { Component, inject, signal } from '@angular/core';
import { Dispatch, DispatchService } from '../dispatch.service';

/** The dispatch board: every dispatch, filterable by status, with cancel for open ones. */
@Component({
  selector: 'nwd-dispatch-board',
  template: `
    <section>
      <h2>Dispatch board</h2>
      <label>
        Status
        <select (change)="filter($event)">
          <option value="">All</option>
          @for (status of statuses; track status) {
            <option [value]="status">{{ status }}</option>
          }
        </select>
      </label>
      <table>
        <thead><tr><th>Reference</th><th>Status</th><th>Route</th><th>Driver</th><th></th></tr></thead>
        <tbody>
          @for (dispatch of dispatches(); track dispatch.id) {
            <tr>
              <td>{{ dispatch.reference }}</td>
              <td>{{ dispatch.status }}</td>
              <td>{{ dispatch.origin }} to {{ dispatch.destination }}</td>
              <td>{{ dispatch.driverName ?? 'Unassigned' }}</td>
              <td>
                @if (dispatch.status !== 'Delivered' && dispatch.status !== 'Cancelled') {
                  <button type="button" (click)="cancel(dispatch)">Cancel</button>
                }
              </td>
            </tr>
          }
        </tbody>
      </table>
    </section>
  `,
})
export class DispatchBoardComponent {
  private readonly service = inject(DispatchService);
  readonly statuses = ['Pending', 'Assigned', 'InTransit', 'Delivered', 'Cancelled'];
  readonly dispatches = signal<Dispatch[]>([]);
  private status = '';

  constructor() {
    this.load();
  }

  filter(event: Event): void {
    this.status = (event.target as HTMLSelectElement).value;
    this.load();
  }

  cancel(dispatch: Dispatch): void {
    this.service.cancel(dispatch.id).subscribe(() => this.load());
  }

  private load(): void {
    this.service.list(this.status || undefined).subscribe((dispatches) => this.dispatches.set(dispatches));
  }
}
