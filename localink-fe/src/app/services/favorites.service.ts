import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class FavoritesService {

  private apiUrl = 'http://localhost:5138/api/v1/favorites';

  constructor(private http: HttpClient) {}

  getFavorites(userId: number): Observable<number[]> {
    return this.http.get<number[]>(`${this.apiUrl}/user/${userId}`);
  }

  addFavorite(userId: number, businessId: number): Observable<any> {
    return this.http.post(`${this.apiUrl}/add`, {
      userId,
      businessId
    });
  }

  removeFavorite(userId: number, businessId: number): Observable<any> {
    return this.http.delete(
      `${this.apiUrl}/remove?userId=${userId}&businessId=${businessId}`
    );
  }
}
