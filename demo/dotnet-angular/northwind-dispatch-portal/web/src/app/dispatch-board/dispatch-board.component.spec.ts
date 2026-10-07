import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { DispatchService } from '../dispatch.service';
import { aDispatch } from '../testing';
import { DispatchBoardComponent } from './dispatch-board.component';

describe('DispatchBoardComponent', () => {
  const list = jest.fn();
  const cancel = jest.fn();

  beforeEach(() => {
    list.mockReset().mockReturnValue(of([aDispatch(), aDispatch({ id: 3, reference: 'NWD-1003', status: 'Pending', driverName: null })]));
    cancel.mockReset().mockReturnValue(of(undefined));
    TestBed.configureTestingModule({
      imports: [DispatchBoardComponent],
      providers: [{ provide: DispatchService, useValue: { list, cancel } }],
    });
  });

  function render() {
    const fixture = TestBed.createComponent(DispatchBoardComponent);
    fixture.detectChanges();
    const rows = () => Array.from(fixture.nativeElement.querySelectorAll('tbody tr') as NodeListOf<HTMLElement>);
    return { fixture, rows };
  }

  it('shows Unassigned when a dispatch has no driver', () => {
    const { rows } = render();

    expect(rows()[1].textContent).toContain('Unassigned');
  });

  it('cancels a dispatch, then reloads the board', () => {
    const { fixture, rows } = render();

    (rows()[0].querySelector('button') as HTMLButtonElement).click();
    fixture.detectChanges();

    expect(cancel).toHaveBeenCalledWith(1);
    expect(list).toHaveBeenCalledTimes(2);
  });
});
