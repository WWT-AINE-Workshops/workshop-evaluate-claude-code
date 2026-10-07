import { Component, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { Subject, filter, map, mergeMap } from 'rxjs';
import { Dispatch, DispatchService } from '../dispatch.service';

/** Typeahead search by reference or destination. Results update as the dispatcher types. */
@Component({
  selector: 'nwd-dispatch-search',
  template: `
    <label>
      Find a dispatch
      <input type="search" placeholder="NWD-1001 or a city" (input)="onInput($event)" />
    </label>
    <ul class="results">
      @for (dispatch of results(); track dispatch.id) {
        <li>{{ dispatch.reference }}: {{ dispatch.origin }} to {{ dispatch.destination }}</li>
      }
    </ul>
  `,
})
export class DispatchSearchComponent {
  private readonly dispatches = inject(DispatchService);
  private readonly query$ = new Subject<string>();

  readonly results = toSignal(
    this.query$.pipe(
      map((query) => query.trim()),
      filter((query) => query.length >= 2),
      mergeMap((query) => this.dispatches.search(query)),
    ),
    { initialValue: [] as Dispatch[] },
  );

  onInput(event: Event): void {
    this.query$.next((event.target as HTMLInputElement).value);
  }
}
