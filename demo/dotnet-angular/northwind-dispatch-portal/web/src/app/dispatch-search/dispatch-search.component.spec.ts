import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { DispatchService } from '../dispatch.service';
import { aDispatch, typeInto } from '../testing';
import { DispatchSearchComponent } from './dispatch-search.component';

describe('DispatchSearchComponent', () => {
  const search = jest.fn();

  beforeEach(() => {
    search.mockReset();
    TestBed.configureTestingModule({
      imports: [DispatchSearchComponent],
      providers: [{ provide: DispatchService, useValue: { search } }],
    });
  });

  function render() {
    const fixture = TestBed.createComponent(DispatchSearchComponent);
    fixture.detectChanges();
    const input = fixture.nativeElement.querySelector('input') as HTMLInputElement;
    const items = () => Array.from(fixture.nativeElement.querySelectorAll('li') as NodeListOf<HTMLElement>).map((li) => li.textContent?.trim());
    return { fixture, input, items };
  }

  it('shows matches for the query', () => {
    search.mockReturnValue(of([aDispatch({ id: 3, reference: 'NWD-1003', destination: 'Salem' })]));
    const { fixture, input, items } = render();

    typeInto(input, 'NWD-1003');
    fixture.detectChanges();

    expect(search).toHaveBeenCalledWith('NWD-1003');
    expect(items()).toEqual(['NWD-1003: Portland to Salem']);
  });

  it('does not search for fewer than two characters', () => {
    const { fixture, input } = render();

    typeInto(input, 'N');
    fixture.detectChanges();

    expect(search).not.toHaveBeenCalled();
  });
});
