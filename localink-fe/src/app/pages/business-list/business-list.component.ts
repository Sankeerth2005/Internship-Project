import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { TranslateModule } from '@ngx-translate/core';

import { BusinessListService } from '../../services/business-list.service';

@Component({
  selector: 'app-business-list',
  standalone: true,
  imports: [CommonModule, RouterModule, TranslateModule],
  templateUrl: './business-list.component.html',
  styleUrls: ['./business-list.component.css']
})
export class BusinessListComponent implements OnInit {

  category = '';
  subcategory = '';

  businesses: any[] = [];
  paginatedBusinesses: any[] = [];

  currentPage = 1;
  pageSize = 5;
  totalPages = 1;

  constructor(
    private route: ActivatedRoute,
    private service: BusinessListService
  ) {}

  categoryId!: number;
  categoryName = '';
  subcategoryName = '';
  subcategoryId!: number;

  ngOnInit() {

    this.categoryId = Number(
      this.route.snapshot.paramMap.get('categoryId')
    );

    this.subcategoryId = Number(
      this.route.snapshot.paramMap.get('subcategoryId')
    );

    this.categoryName =
      this.route.snapshot.queryParamMap.get('categoryName') || '';

    this.subcategoryName =
      this.route.snapshot.queryParamMap.get('subcategoryName') || '';

    this.service.getBusinessesBySubcategory(this.subcategoryId)
      .subscribe({
        next: (data) => {
          this.businesses = data.map((b: any) => ({
            ...b,
            primaryImage: b.primaryImage
              ? b.primaryImage
              : null
          }));

          this.totalPages = Math.ceil(this.businesses.length / this.pageSize);
          this.updatePage();
        },
        error: (err) => {
          console.error('Error fetching businesses', err);
        }
      });
  }
  updatePage() {

    const start = (this.currentPage - 1) * this.pageSize;
    const end = start + this.pageSize;

    this.paginatedBusinesses = this.businesses.slice(start, end);

  }

  changePage(page:number){

    if(page < 1 || page > this.totalPages) return;

    this.currentPage = page;

    this.updatePage();
  }
}