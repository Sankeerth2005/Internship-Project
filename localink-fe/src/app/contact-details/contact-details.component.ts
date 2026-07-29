import {
  Component,
  EventEmitter,
  Output,
  Input,
  OnInit,
  AfterViewInit,
  OnDestroy,
  OnChanges,
  PLATFORM_ID,
  Inject,
  SimpleChanges
} from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { NgSelectModule } from '@ng-select/ng-select';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Subject, of } from 'rxjs';
import { debounceTime, distinctUntilChanged, switchMap, catchError } from 'rxjs/operators';
import { TranslateModule } from '@ngx-translate/core';
import { BusinessLocationService } from '../services/business-location.service';
import { BusinessPincodeService } from '../services/business-pincode.service';

@Component({
  selector: 'app-contact-details',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, NgSelectModule, FormsModule, TranslateModule],
  templateUrl: './contact-details.component.html',
  styleUrls: ['./contact-details.component.css']
})
export class ContactDetailsComponent implements OnInit, OnChanges, AfterViewInit, OnDestroy {

  contactForm!: FormGroup;

  @Input() initialData: any;

  @Output() next = new EventEmitter<any>();

  @Output() previous = new EventEmitter<void>();

  phoneCountries: any[] = [];

  countries: any[] = [];
  states: any[] = [];
  cities: any[] = [];

  // Map related
  private map: any;
  private marker: any;
  private L: any;

  isLoadingLocation = false;
  locationError = '';
  searchQuery = '';
  selectedLat: number | null = null;
  selectedLng: number | null = null;
  isGeocodingAddress = false;

  // Autocomplete search
  searchQuerySubject = new Subject<string>();
  searchResults: any[] = [];
  isSearching = false;
  showDropdown = false;

  // API base URL
  baseUrl = 'http://localhost:5138/api/v1/location';

  constructor(
    private fb: FormBuilder,
    private http: HttpClient,
    private locationService: BusinessLocationService,
    private pincodeService: BusinessPincodeService,
    @Inject(PLATFORM_ID) private platformId: Object
  ) {

    this.contactForm = this.fb.group({
      phoneCode: ['+91', Validators.required],
      phone: [
        '',
        [
          Validators.required,
          Validators.pattern(/^[3-9][0-9]{9}$/)
        ]
      ],
      email: [
        '',
        [
          Validators.required,
          Validators.pattern(/^[a-zA-Z][a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/)
        ]
      ],
      website: [
        '',
        Validators.pattern(/^(https?:\/\/)?(www\.)?[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$/)
      ],
      address: ['', [
        Validators.required,
        Validators.minLength(5),
        Validators.maxLength(200)
      ]],

      city: ['', [
        Validators.required,
        Validators.minLength(2),
        Validators.maxLength(50),
        Validators.pattern(/^[a-zA-Z\s.-]+$/)
      ]],

      state: ['', Validators.required],

      country: ['', Validators.required],

      pincode: [
        '',
        [Validators.required, Validators.pattern(/^[1-9][0-9]{5}$/)]
      ],

      latitude: [null],
      longitude: [null]

    }, {
      validators: this.countryPhoneValidator.bind(this)
    });

    /* Dynamic phone validation */
    this.contactForm.get('phoneCode')?.valueChanges.subscribe(code => {
      const phoneControl = this.contactForm.get('phone');
      const numericCode = code?.replace('+', '');
      if (numericCode === '91') {
        phoneControl?.setValidators([
          Validators.required,
          Validators.pattern(/^[3-9][0-9]{9}$/)
        ]);
      } else {
        phoneControl?.setValidators([
          Validators.required,
          Validators.pattern(/^(?!0+$)[0-9]{6,15}$/)
        ]);
      }

      phoneControl?.updateValueAndValidity();
    });
  }

  ngOnInit() {
    if (isPlatformBrowser(this.platformId)) {
      this.locationService.getCountries()
        .subscribe((data: any[]) => {
          this.countries = data;
          this.phoneCountries = data.map((c: any) => ({
            name: c.name,
            code: c.phonecode?.startsWith('+') ? c.phonecode : `+${c.phonecode || ''}`,
            flag: '',
            searchLabel: `${c.name} +${c.phonecode || c.phone_code}`
          }));

          if (this.initialData) {
            // Handle phone data - support both combined and separate formats
            let phoneCode = this.initialData.phoneCode || '';
            let phoneNumber = this.initialData.phone || '';

            // If phone contains code+number combined (e.g., "+91 9876543210")
            if (this.initialData.phone && this.initialData.phone.includes(' ')) {
              const [code, ...numberParts] = this.initialData.phone.split(' ');
              phoneCode = code.replace('+', '');
              phoneNumber = numberParts.join(' ');
            }

            this.contactForm.patchValue({
              ...this.initialData,
              phoneCode: phoneCode,
              phone: phoneNumber
            });

            // Load states for the selected country
            const countryObj = this.countries.find(
              c => c.name === this.initialData.country
            );
            if (countryObj) {
              this.locationService.getStates(countryObj.iso2)
                .subscribe(res => {
                  this.states = res;
                  // Restore map pin if coordinates exist
                  if (this.initialData.latitude && this.initialData.longitude) {
                    this.selectedLat = this.initialData.latitude;
                    this.selectedLng = this.initialData.longitude;
                  }
                });
            }
          }
        });
    }

    // Setup auto-search observable
    this.searchQuerySubject.pipe(
      debounceTime(500),
      distinctUntilChanged(),
      switchMap(query => {
        if (!query.trim()) {
          this.searchResults = [];
          this.showDropdown = false;
          return of([]);
        }
        this.isSearching = true;
        const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(query)}&format=json&limit=5`;
        return this.http.get<any[]>(url, { headers: { 'Accept-Language': 'en' } }).pipe(
          catchError(() => {
            this.locationError = 'Auto-search failed.';
            return of([]);
          })
        );
      })
    ).subscribe(results => {
      this.isSearching = false;
      this.searchResults = results || [];
      this.showDropdown = this.searchResults.length > 0;
    });
  }

  async ngAfterViewInit() {
    if (!isPlatformBrowser(this.platformId)) return;

    // Dynamically import leaflet to avoid SSR issues
    this.L = await import('leaflet');

    // Fix default marker icon paths broken by webpack
    delete (this.L.Icon.Default.prototype as any)._getIconUrl;
    this.L.Icon.Default.mergeOptions({
      iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
      iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
      shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
    });

    // Use setTimeout(0) so the map initialises AFTER Angular finishes
    // rendering the DOM — without this Leaflet miscalculates container
    // dimensions when inside an *ngIf and only renders a partial tile set.
    setTimeout(() => {
      // Initialize map centered on India
      this.map = this.L.map('leaflet-map', {
        center: [20.5937, 78.9629],
        zoom: 5
      });

      this.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
        maxZoom: 19
      }).addTo(this.map);

      // Force the map to recalculate its container size
      this.map.invalidateSize();

      // If we already have coordinates (returning to step), place marker
      if (this.selectedLat && this.selectedLng) {
        this.placeMarker(this.selectedLat, this.selectedLng);
        this.map.setView([this.selectedLat, this.selectedLng], 15);
      }

      // Map click handler
      this.map.on('click', (e: any) => {
        const { lat, lng } = e.latlng;
        this.placeMarker(lat, lng);
        this.reverseGeocode(lat, lng);
      });
    }, 0);
  }

  ngOnDestroy() {
    if (this.map) {
      this.map.remove();
      this.map = null;
    }
  }

  ngOnChanges(changes: SimpleChanges) {
    // Handle when initialData arrives after component initialization
    if (changes['initialData'] && this.initialData && this.countries.length > 0) {
      // Process initialData same as in ngOnInit
      let phoneCode = this.initialData.phoneCode || '';
      let phoneNumber = this.initialData.phone || '';

      // If phone contains code+number combined (e.g., "+91 9876543210")
      if (this.initialData.phone && this.initialData.phone.includes(' ')) {
        const [code, ...numberParts] = this.initialData.phone.split(' ');
        phoneCode = code.replace('+', '');
        phoneNumber = numberParts.join(' ');
      }

      this.contactForm.patchValue({
        ...this.initialData,
        phoneCode: phoneCode,
        phone: phoneNumber
      });

      // Load states for the selected country
      const countryObj = this.countries.find(
        c => c.name === this.initialData.country
      );
      if (countryObj) {
        this.locationService.getStates(countryObj.iso2)
          .subscribe(res => {
            this.states = res;
            // Load cities if state exists
            if (this.initialData.state) {
              const stateObj = this.states.find((s: any) => s.name === this.initialData.state);
              if (stateObj) {
                this.locationService.getCities(countryObj.iso2, stateObj.iso2)
                  .subscribe(citiesRes => {
                    this.cities = citiesRes;
                  });
              }
            }
            // Restore map pin if coordinates exist
            if (this.initialData.latitude && this.initialData.longitude) {
              this.selectedLat = this.initialData.latitude;
              this.selectedLng = this.initialData.longitude;
            }
          });
      }
    }
  }

  // ---- MAP HELPERS ----

  private placeMarker(lat: number, lng: number) {
    this.selectedLat = lat;
    this.selectedLng = lng;

    if (this.marker) {
      this.marker.setLatLng([lat, lng]);
    } else {
      this.marker = this.L.marker([lat, lng], { draggable: true }).addTo(this.map);

      this.marker.on('dragend', () => {
        const pos = this.marker.getLatLng();
        this.selectedLat = pos.lat;
        this.selectedLng = pos.lng;
        this.reverseGeocode(pos.lat, pos.lng);
      });
    }

    this.contactForm.patchValue({ latitude: lat, longitude: lng });
  }

  // ---- CURRENT LOCATION ----

  useCurrentLocation() {
    if (!isPlatformBrowser(this.platformId)) return;

    if (!navigator.geolocation) {
      this.locationError = 'Geolocation is not supported by your browser.';
      return;
    }

    this.isLoadingLocation = true;
    this.locationError = '';

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const lat = position.coords.latitude;
        const lng = position.coords.longitude;

        this.map.flyTo([lat, lng], 16, { animate: true, duration: 1.5 });
        this.placeMarker(lat, lng);
        this.reverseGeocode(lat, lng);
        this.isLoadingLocation = false;
      },
      (error) => {
        this.isLoadingLocation = false;
        switch (error.code) {
          case error.PERMISSION_DENIED:
            this.locationError = 'Location access denied. Please allow permission in your browser.';
            break;
          case error.POSITION_UNAVAILABLE:
            this.locationError = 'Location information is unavailable.';
            break;
          case error.TIMEOUT:
            this.locationError = 'Location request timed out.';
            break;
          default:
            this.locationError = 'An error occurred while retrieving your location.';
        }
      },
      { timeout: 10000, enableHighAccuracy: true }
    );
  }

  // ---- REVERSE GEOCODING ----

  reverseGeocode(lat: number, lng: number) {
    this.isGeocodingAddress = true;

    const url = `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}&format=json&addressdetails=1`;

    this.http.get<any>(url, {
      headers: { 'Accept-Language': 'en' }
    }).subscribe({
      next: (data) => {
        this.isGeocodingAddress = false;
        const addr = data.address;

        if (!addr) return;

        const countryName = addr.country || '';
        const stateName = addr.state || addr.region || '';
        const cityName = addr.city || addr.town || addr.village || addr.county || '';
        const postcode = addr.postcode || '';
        const streetParts = [
          addr.road || addr.street,
          addr.house_number,
          addr.suburb,
          addr.neighbourhood
        ].filter(Boolean);
        const streetAddress = streetParts.join(', ') || data.display_name || '';

        // Check if country exists in our list
        const countryObj = this.countries.find(
          c => c.name.toLowerCase() === countryName.toLowerCase()
        );
        const matchedCountry = countryObj ? countryObj.name : countryName;

        if (countryObj) {
          this.locationService.getStates(countryObj.iso2)
            .subscribe(res => {
              this.states = res;
              // Find matching state from API states
              const matchedStateObj = this.states.find(
                (s: any) => s.name.toLowerCase() === stateName.toLowerCase()
              );
              const matchedState = matchedStateObj ? matchedStateObj.name : stateName;

              // Load cities if state match found
              if (matchedStateObj) {
                this.locationService.getCities(countryObj.iso2, matchedStateObj.iso2)
                  .subscribe(citiesRes => {
                    this.cities = citiesRes;
                  });
              }

              this.contactForm.patchValue({
                country: matchedCountry,
                state: matchedState,
                city: cityName,
                pincode: postcode.replace(/\s/g, '').slice(0, 6),
                address: streetAddress.slice(0, 200)
              });
            });
        } else {
          this.contactForm.patchValue({
            country: matchedCountry,
            state: stateName,
            city: cityName,
            pincode: postcode.replace(/\s/g, '').slice(0, 6),
            address: streetAddress.slice(0, 200)
          });
        }

    if (countryObj && countryObj.code) {
          const currentPhoneCode = this.contactForm.get('phoneCode')?.value;
          if (!currentPhoneCode || currentPhoneCode === '+91') {
            const formattedCode = countryObj.code?.startsWith('+') ? countryObj.code : `+${countryObj.code}`;
            this.contactForm.patchValue({ phoneCode: formattedCode });
          }
        }
      },
      error: () => {
        this.isGeocodingAddress = false;
        this.locationError = 'Could not fetch address for this location.';
      }
    });
  }

  // ---- FORWARD GEOCODING / SEARCH ----

  onSearchQueryChange(query: string) {
    this.searchQuerySubject.next(query);
  }

  selectSearchResult(result: any) {
    this.showDropdown = false;
    this.searchQuery = result.display_name;
    const lat = parseFloat(result.lat);
    const lon = parseFloat(result.lon);

    this.map.flyTo([lat, lon], 15, { animate: true, duration: 1.5 });
    this.placeMarker(lat, lon);
    this.reverseGeocode(lat, lon);
    this.locationError = '';
  }

  // Click outside dropdown or focus out
  closeDropdown() {
    setTimeout(() => {
      this.showDropdown = false;
    }, 200);
  }

  searchLocation() {
    if (!this.searchQuery.trim()) return;

    this.showDropdown = false;
    const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(this.searchQuery)}&format=json&limit=1`;

    this.http.get<any[]>(url, {
      headers: { 'Accept-Language': 'en' }
    }).subscribe({
      next: (results) => {
        if (results && results.length > 0) {
          const { lat, lon } = results[0];
          const latitude = parseFloat(lat);
          const longitude = parseFloat(lon);

          this.map.flyTo([latitude, longitude], 15, { animate: true, duration: 1.5 });
          this.placeMarker(latitude, longitude);
          this.reverseGeocode(latitude, longitude);
          this.locationError = '';
        } else {
          this.locationError = 'No results found for that location. Try a different search.';
        }
      },
      error: () => {
        this.locationError = 'Search failed. Please try again.';
      }
    });
  }

  onSearchKeydown(event: KeyboardEvent) {
    if (event.key === 'Enter') {
      event.preventDefault();
      this.searchLocation();
    }
  }

  allowOnlyNumbers(event: any) {
    event.target.value = event.target.value.replace(/[^0-9]/g, '');
  }

  countryPhoneValidator(form: any) {
    const phoneControl = form.get('phone');
    const phoneCodeControl = form.get('phoneCode');

    if (!phoneControl || !phoneCodeControl) return null;

    const phone = phoneControl.value;
    const code = phoneCodeControl.value;
    const numericCode = code?.replace('+', '');

    if (!phone || !code) return null;

    if (numericCode === '91') {
      if (!/^[3-9][0-9]{9}$/.test(phone)) {
        return { countryMismatch: true };
      }
    } else {
      if (!/^(?!0+$)[0-9]{6,15}$/.test(phone)) {
        return { countryMismatch: true };
      }
    }

    return null;
  }

  onCountryChange() {
    const selectedCountry = this.contactForm.get('country')?.value;

    this.states = [];
    this.cities = [];

    this.contactForm.patchValue({
      state: '',
      city: '',
      pincode: ''
    });

    if (!selectedCountry) return;

    // AUTO-UPDATE PHONE CODE
    const countryObj = this.countries.find(c => c.name === selectedCountry);
    if (countryObj && (countryObj.phonecode || countryObj.phone_code)) {
      const rawCode = countryObj.phonecode || countryObj.phone_code || '';
      const formattedCode = rawCode.startsWith('+') ? rawCode : `+${rawCode}`;
      this.contactForm.get('phoneCode')?.setValue(formattedCode);
    }

    this.locationService.getStates(countryObj?.iso2 || '')
      .subscribe(res => {
        this.states = res;
      });
  }

  onStateChange(event: any) {
    const selectedCountry = this.contactForm.get('country')?.value;
    const selectedState = this.contactForm.get('state')?.value;

    this.cities = [];
    this.contactForm.patchValue({ city: '', pincode: '' });

    if (!selectedCountry || !selectedState) return;

    const countryObj = this.countries.find(c => c.name === selectedCountry);
    const stateObj = this.states.find((s: any) => s.name === selectedState);

    this.locationService.getCities(countryObj?.iso2 || '', stateObj?.iso2 || '')
      .subscribe(res => {
        this.cities = res;
      });
  }

  /* ===========================
     PINCODE VALIDATION
  =========================== */
  validatePincode() {
    const control = this.contactForm.get('pincode');
    const pincode = control?.value;

    if (!pincode || pincode.length < 5) return;

    //  CLEAR OLD ERRORS FIRST
    control?.setErrors(null);

    this.pincodeService.validate(pincode)
      .subscribe({
        next: (res: any) => {
          if (!res || !res.country) {
            control?.setErrors({ invalidPincode: true });
            return;
          }

          const apiCountry = res.country;
          const apiState = res.state;
          const apiCity = res.city;

          const selectedCountry = this.contactForm.get('country')?.value;
          const selectedState = this.contactForm.get('state')?.value;
          const selectedCity = this.contactForm.get('city')?.value;

          const normalize = (val: string) =>
            val?.toLowerCase().replace(/\s/g, '');

          //  COUNTRY CHECK
          if (selectedCountry &&
              normalize(apiCountry) !== normalize(selectedCountry)) {
            control?.setErrors({ ...control.errors, invalidCountry: true });
            return;
          }

          //  STATE CHECK
          if (selectedState &&
              normalize(apiState) !== normalize(selectedState)) {
            control?.setErrors({ ...control.errors, invalidState: true });
            return;
          }

          //  CITY CHECK
          if (selectedCity && apiCity &&
              normalize(apiCity) !== normalize(selectedCity)) {
            control?.setErrors({ ...control.errors, invalidCity: true });
            return;
          }

          //  SUCCESS → CLEAR EVERYTHING
          control?.setErrors(null);
        },
        error: (err) => {
          console.error("API ERROR:", err);
          control?.setErrors({ invalidPincode: true });
        }
      });
  }

  previousStep() {
    this.previous.emit();
  }

  submit() {
    if (this.contactForm.valid) {
      const formValue = this.contactForm.value;
      const phoneCode = formValue.phoneCode;
      const phone = formValue.phone;
      const fullPhone = phone.startsWith('+') ? phone : `${phoneCode} ${phone}`;

      const data = {
        ...formValue,
        phone: fullPhone
      };

      this.next.emit(data);
    } else {
      this.contactForm.markAllAsTouched();
    }
  }
}

