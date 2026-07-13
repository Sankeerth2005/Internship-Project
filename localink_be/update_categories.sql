-- Disable foreign key constraints to clear categories safely
ALTER TABLE [subcategory] DROP CONSTRAINT [FK_subcategory_category_category_id];
ALTER TABLE [business] DROP CONSTRAINT [FK_business_category_category_id];
ALTER TABLE [business] DROP CONSTRAINT [FK_business_subcategory_subcategory_id];
GO

-- Truncate existing categories/subcategories (and delete existing businesses if needed since categories have changed)
DELETE FROM [business_reviews];
DELETE FROM [business_photos];
DELETE FROM [business_contact];
DELETE FROM [business_hour_slots];
DELETE FROM [business_hours];
DELETE FROM [business_metric];
DELETE FROM [Favorites];
DELETE FROM [admin_dashboard];
DELETE FROM [business];
DELETE FROM [subcategory];
DELETE FROM [category];
GO

-- Reset identity seeds
DBCC CHECKIDENT ('category', RESEED, 0);
DBCC CHECKIDENT ('subcategory', RESEED, 0);
GO

-- Re-enable constraints
ALTER TABLE [subcategory] ADD CONSTRAINT [FK_subcategory_category_category_id] FOREIGN KEY ([category_id]) REFERENCES [category] ([category_id]) ON DELETE CASCADE;
ALTER TABLE [business] ADD CONSTRAINT [FK_business_category_category_id] FOREIGN KEY ([category_id]) REFERENCES [category] ([category_id]);
ALTER TABLE [business] ADD CONSTRAINT [FK_business_subcategory_subcategory_id] FOREIGN KEY ([subcategory_id]) REFERENCES [subcategory] ([subcategory_id]);
GO

-- Insert Categories
INSERT INTO [category] ([category_name], [icon_url]) VALUES
('Restaurants & Cafes', 'restaurant_menu'),
('Health & Wellness', 'local_hospital'),
('Services', 'home_repair_service'),
('Automotive', 'directions_car'),
('Beauty & Wellness', 'spa'),
('Shopping & Retail', 'shopping_bag'),
('Education', 'school'),
('Travel', 'flight'),
('Real Estate', 'apartment'),
('Legal', 'gavel'),
('IT & Technology', 'computer'),
('Marketing & Advertising', 'campaign'),
('Entertainment', 'sports_esports'),
('Religious', 'temple_hindu'),
('Finance', 'account_balance'),
('Pets', 'pets'),
('Security', 'security'),
('Miscellaneous', 'more_horiz');
GO

-- Insert Subcategories
-- 1. Restaurants & Cafes (ID: 1)
INSERT INTO [subcategory] ([subcategory_name], [category_id]) VALUES
('Restaurants', 1),
('Cafes', 1),
('Fast Food', 1),
('Bakeries', 1),
('Street Food', 1),
('Ice Cream Parlours', 1),
('Home Chefs', 1),
('Catering', 1),
('Cloud Kitchens', 1),
('Juice Centres', 1);

-- 2. Health & Wellness (ID: 2)
INSERT INTO [subcategory] ([subcategory_name], [category_id]) VALUES
('Clinics', 2),
('Hospitals', 2),
('Doctors', 2),
('Dentists', 2),
('Veterinary Clinic', 2),
('Physiotherapy Centres', 2),
('Diagnostics Centres', 2),
('Alternative Medicine (Ayurveda, Homeopathy, etc.)', 2),
('Med Store', 2),
('Gyms', 2);

-- 3. Services (ID: 3)
INSERT INTO [subcategory] ([subcategory_name], [category_id]) VALUES
('Plumbers', 3),
('Electricians', 3),
('Carpenters', 3),
('Painters', 3),
('Pest Control', 3),
('Cleaning Services', 3),
('Laundry / Dryclean', 3),
('Tailors / Boutiques', 3),
('Packer & Movers', 3),
('Rental Agencies', 3);

-- 4. Automotive (ID: 4)
INSERT INTO [subcategory] ([subcategory_name], [category_id]) VALUES
('Car Service', 4),
('Bike Service', 4),
('Car Accessories', 4),
('Bike Accessories', 4),
('Car Washing', 4),
('Tyre Shops', 4),
('Battery Shops', 4),
('EV Charging Stations', 4);

-- 5. Beauty & Wellness (ID: 5)
INSERT INTO [subcategory] ([subcategory_name], [category_id]) VALUES
('Beauty Parlours', 5),
('Salons', 5),
('Spas', 5),
('Barber Shops', 5),
('Tattoo Studios', 5),
('Makeup Artists', 5),
('Nail Salons', 5);

-- 6. Shopping & Retail (ID: 6)
INSERT INTO [subcategory] ([subcategory_name], [category_id]) VALUES
('Grocery Stores', 6),
('Supermarket', 6),
('Clothing Stores', 6),
('Footwear Stores', 6),
('Jewelery Shops', 6),
('Mobile Shops', 6),
('Electronics Stores', 6),
('Furniture Stores', 6),
('Gift Shops', 6),
('Stationery Stores', 6);

-- 7. Education (ID: 7)
INSERT INTO [subcategory] ([subcategory_name], [category_id]) VALUES
('Schools', 7),
('Colleges', 7),
('Coaching Centres', 7),
('Hobby Classes', 7),
('Preschools / Daycare', 7);

-- 8. Travel (ID: 8)
INSERT INTO [subcategory] ([subcategory_name], [category_id]) VALUES
('Travel Agency', 8),
('Tour Operator', 8),
('Taxi Services', 8),
('Rent A Car', 8),
('Bus Services', 8),
('Flight Booking', 8),
('Hotel Booking', 8);

-- 9. Real Estate (ID: 9)
INSERT INTO [subcategory] ([subcategory_name], [category_id]) VALUES
('Property Dealers', 9),
('Builders', 9),
('Architects', 9),
('Interior Designers', 9),
('Paying Guest', 9);

-- 10. Legal (ID: 10)
INSERT INTO [subcategory] ([subcategory_name], [category_id]) VALUES
('Advocates', 10),
('Notaries', 10),
('Legal Advisors', 10),
('Document Writers', 10);

-- 11. IT & Technology (ID: 11)
INSERT INTO [subcategory] ([subcategory_name], [category_id]) VALUES
('Software Development', 11),
('Web Design', 11),
('App Development', 11),
('Digital Marketing', 11),
('Computer Repair', 11),
('CCTV & Security', 11);

-- 12. Marketing & Advertising (ID: 12)
INSERT INTO [subcategory] ([subcategory_name], [category_id]) VALUES
('Flex & Banner Printing', 12),
('Event Planner', 12),
('Advertising Agency', 12),
('Printing Press', 12),
('Photography Studios', 12);

-- 13. Entertainment (ID: 13)
INSERT INTO [subcategory] ([subcategory_name], [category_id]) VALUES
('Theatres', 13),
('Gaming Zone', 13),
('Amusement Parks', 13),
('Sports Clubs', 13),
('Resorts', 13);

-- 14. Religious (ID: 14)
INSERT INTO [subcategory] ([subcategory_name], [category_id]) VALUES
('Temples', 14),
('Gurudwaras', 14),
('Mosques', 14),
('Churches', 14),
('Spiritual Organisations', 14);

-- 15. Finance (ID: 15)
INSERT INTO [subcategory] ([subcategory_name], [category_id]) VALUES
('Banks', 15),
('ATMs', 15),
('Insurance Agents', 15),
('Loan Advisors', 15),
('Financial Planners', 15);

-- 16. Pets (ID: 16)
INSERT INTO [subcategory] ([subcategory_name], [category_id]) VALUES
('Pet Shop', 16),
('Pet Clinic / Vet', 16),
('Pet Grooming Services', 16),
('Dog Training', 16);

-- 17. Security (ID: 17)
INSERT INTO [subcategory] ([subcategory_name], [category_id]) VALUES
('Security Agencies', 17),
('CCTV Installation', 17),
('Access Control Systems', 17),
('Fire Safety Services', 17);

-- 18. Miscellaneous (ID: 18)
INSERT INTO [subcategory] ([subcategory_name], [category_id]) VALUES
('Library', 18),
('Music Studio', 18),
('Astrology', 18),
('Photo Studio', 18),
('Courier Service', 18),
('Internet Cafe', 18);
GO
