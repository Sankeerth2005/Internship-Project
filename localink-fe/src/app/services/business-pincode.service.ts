import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
@Injectable({
  providedIn: 'root'
})
export class BusinessPincodeService {

  private baseUrl = 'http://localhost:5138/api/v1/BusinessPincode';

  constructor(private http: HttpClient) {}

  validate(postcode: string): Observable<any> {
    return this.http.get(`${this.baseUrl}/validate`, {
      params: { postcode }
    });
  }
}