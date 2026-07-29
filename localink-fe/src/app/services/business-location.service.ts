import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { tap, shareReplay } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class BusinessLocationService {

  private baseUrl = 'http://localhost:5138/api/v1/location'; // your backend

  // CACHE OBSERVABLES
  private countriesCache$: Observable<any> | null = null;
  private statesCache = new Map<string, Observable<any>>();
  private citiesCache = new Map<string, Observable<any>>();

  constructor(private http: HttpClient) {}

  getCountries(): Observable<any> {
    if (!this.countriesCache$) {
      this.countriesCache$ = this.http.get(`${this.baseUrl}/countries`).pipe(
        shareReplay(1)
      );
    }
    return this.countriesCache$;
  }

  getStates(countryCode: string): Observable<any> {
    if (!this.statesCache.has(countryCode)) {
      const request$ = this.http.get(`${this.baseUrl}/states/${countryCode}`).pipe(
        shareReplay(1)
      );
      this.statesCache.set(countryCode, request$);
    }
    return this.statesCache.get(countryCode)!;
  }

  getCities(countryCode: string, stateCode: string): Observable<any> {
    const key = `${countryCode}-${stateCode}`;
    if (!this.citiesCache.has(key)) {
      const request$ = this.http.get(`${this.baseUrl}/cities/${countryCode}/${stateCode}`).pipe(
        shareReplay(1)
      );
      this.citiesCache.set(key, request$);
    }
    return this.citiesCache.get(key)!;
  }
}