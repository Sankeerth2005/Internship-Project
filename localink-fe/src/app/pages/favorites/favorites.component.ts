import { Component, OnInit, Inject, PLATFORM_ID } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { TranslateModule } from '@ngx-translate/core';
import { LanguageSwitcherComponent } from '../../components/language-switcher/language-switcher.component';
import { FavoritesService } from '../../services/favorites.service';
import { ToastService } from '../../services/toast.service';
import { BusinessListService } from '../../services/business-list.service';
import { ReviewService } from '../../services/review.service';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';

export interface FavoriteBusiness {
  id: number;
  name: string;
  categoryName: string;
  subcategoryName: string;
  description: string;
  primaryImage: string | null;
  rating: number;
  averageRating: number;
}

@Component({
  selector: 'app-favorites',
  standalone: true,
  imports: [CommonModule, TranslateModule, RouterLink, LanguageSwitcherComponent],
  templateUrl: './favorites.component.html',
  styleUrls: ['./favorites.component.css']
})
export class FavoritesComponent implements OnInit {
  favoriteBusinesses: FavoriteBusiness[] = [];
  favoriteIds: number[] = [];
  userId: number = 0;
  isLoading: boolean = true;
  
  // Pagination
  currentPage: number = 1;
  itemsPerPage: number = 9;
  paginatedBusinesses: FavoriteBusiness[] = [];
  totalPages: number = 1;

  constructor(
    private favoritesService: FavoritesService,
    private businessListService: BusinessListService,
    private reviewService: ReviewService,
    private toastService: ToastService,
    private router: Router,
    @Inject(PLATFORM_ID) private platformId: Object
  ) {
    this.extractUserIdFromToken();
  }

  private extractUserIdFromToken(): void {
    if (!isPlatformBrowser(this.platformId)) return;
    const token = localStorage.getItem('token');
    if (!token) return;
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      // Check multiple possible claim names
      const userIdValue = 
        payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ||
        payload.nameid ||
        payload.userId ||
        payload.UserId ||
        payload.sub ||
        '0';
      this.userId = parseInt(userIdValue, 10);
      if (this.userId <= 0) {
        console.error('Invalid userId extracted from token:', userIdValue);
        this.userId = 0;
      }
    } catch (error) {
      console.error('Failed to extract userId from token:', error);
      this.userId = 0;
    }
  }

  ngOnInit(): void {
    if (!isPlatformBrowser(this.platformId)) return;
    this.loadFavorites();
  }

  loadFavorites(): void {
    this.isLoading = true;
    this.favoritesService.getFavorites(this.userId).subscribe({
      next: (ids) => {
        this.favoriteIds = ids;
        if (ids.length > 0) {
          this.loadBusinessDetails(ids);
        } else {
          this.favoriteBusinesses = [];
          this.isLoading = false;
          this.updatePagination();
        }
      },
      error: (err: Error) => {
        console.error('Error loading favorites:', err);
        this.isLoading = false;
      }
    });
  }

  loadBusinessDetails(ids: number[]): void {
    this.favoriteBusinesses = [];
    let loadedCount = 0;
    
    ids.forEach(id => {
      // Fetch business details and review summary in parallel
      forkJoin({
        business: this.businessListService.getBusinessById(id),
        summary: this.reviewService.getSummary(id).pipe(
          catchError(() => of({ averageRating: 0, totalReviews: 0 }))
        )
      }).subscribe({
        next: (result: any) => {
          const business = result.business;
          const summary = result.summary;
          
          const mappedBusiness: FavoriteBusiness = {
            id: business.businessId || business.id,
            name: business.businessName || business.name,
            categoryName: business.categoryName || 'General',
            subcategoryName: business.subcategoryName || '',
            description: business.description || 'No description available',
            primaryImage: business.primaryImage 
              ? business.primaryImage 
              : null,
            rating: summary?.averageRating || business.averageRating || business.rating || 0,
            averageRating: summary?.averageRating || business.averageRating || business.rating || 0
          };
          this.favoriteBusinesses.push(mappedBusiness);
          loadedCount++;
          if (loadedCount === ids.length) {
            this.isLoading = false;
            this.updatePagination();
          }
        },
        error: (err: Error) => {
          console.error(`Error loading business ${id}:`, err);
          loadedCount++;
          if (loadedCount === ids.length) {
            this.isLoading = false;
            this.updatePagination();
          }
        }
      });
    });
  }

  removeFavorite(businessId: number): void {
    this.favoritesService.removeFavorite(this.userId, businessId).subscribe({
      next: () => {
        this.favoriteBusinesses = this.favoriteBusinesses.filter(b => b.id !== businessId);
        this.favoriteIds = this.favoriteIds.filter(id => id !== businessId);
        this.updatePagination();
        this.toastService.success('Removed from favorites');
      },
      error: (err: Error) => {
        console.error('Error removing favorite:', err);
        this.toastService.error('Failed to remove from favorites');
      }
    });
  }

  // Pagination methods
  updatePagination(): void {
    this.totalPages = Math.ceil(this.favoriteBusinesses.length / this.itemsPerPage);
    if (this.currentPage > this.totalPages) {
      this.currentPage = Math.max(1, this.totalPages);
    }
    const start = (this.currentPage - 1) * this.itemsPerPage;
    const end = start + this.itemsPerPage;
    this.paginatedBusinesses = this.favoriteBusinesses.slice(start, end);
  }

  goToPage(page: number): void {
    if (page >= 1 && page <= this.totalPages) {
      this.currentPage = page;
      this.updatePagination();
    }
  }

  nextPage(): void {
    if (this.currentPage < this.totalPages) {
      this.currentPage++;
      this.updatePagination();
    }
  }

  previousPage(): void {
    if (this.currentPage > 1) {
      this.currentPage--;
      this.updatePagination();
    }
  }

  goToBusinessDetail(business: FavoriteBusiness): void {
    this.router.navigate(['/business', business.id], {
      queryParams: {
        categoryName: business.categoryName,
        subcategoryName: business.subcategoryName
      }
    });
  }

  goBack(): void {
    this.router.navigate(['/user-dashboard']);
  }

  getStars(rating: number): string {
    const full = Math.floor(rating);
    const half = rating % 1 >= 0.5 ? 1 : 0;
    const empty = 5 - full - half;
    return '★'.repeat(full) + (half ? '' : '') + '☆'.repeat(empty);
  }
}
