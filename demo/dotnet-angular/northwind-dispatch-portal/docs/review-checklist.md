# Review checklist

Reviewers check every pull request against this list. Comment only where something is wrong or worth changing; say so plainly when a pull request is fine.

1. **Authorization.** Every new or changed endpoint names a policy. `[Authorize]` alone lets any signed-in customer in. Anything that returns data across customers needs `Policies.Admin`.
2. **Contract.** No field in `DispatchDto` renamed, dropped, or retyped without `docs/api.md` and the pull request saying so.
3. **Tests.** New behaviour has a test. Existing tests are not edited to pass. API tests use `DispatchApiFactory` and `ClientAs`; web tests stub `DispatchService`.
4. **Data.** Queries go through EF Core; no SQL built from strings.
5. **RxJS.** A stream that starts a request per input cancels the previous one (`switchMap`), unless the pull request says why not.
6. **Scope.** The pull request does one thing, and the CHANGELOG says what.
