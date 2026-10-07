import { Component } from '@angular/core';
import { DispatchBoardComponent } from './dispatch-board/dispatch-board.component';
import { DispatchSearchComponent } from './dispatch-search/dispatch-search.component';

@Component({
  selector: 'nwd-root',
  imports: [DispatchSearchComponent, DispatchBoardComponent],
  template: `
    <h1>Northwind Dispatch</h1>
    <nwd-dispatch-search />
    <nwd-dispatch-board />
  `,
})
export class AppComponent {}
