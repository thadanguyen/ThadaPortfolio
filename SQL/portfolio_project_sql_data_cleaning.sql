-- Data cleaning process
-- In this project, I will go through some syntaxes that are performed to clean data on SQL
-- The dataset we'll use is NashvilleHousing, which is available through this link:
-- https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/Nashville%20Housing%20Data%20for%20Data%20Cleaning.xlsx

-- A quick look on the dataset
SELECT *
FROM portfolio_project..NashvilleHousing

----------------------------------------------------------------------------------------------------------------------------------------
-- Standardize Date format

 SELECT SaleDate, CONVERT(date, SaleDate)
 FROM portfolio_project..NashvilleHousing;


ALTER TABLE portfolio_project..NashvilleHousing
ADD sale_date_formated Date;

 UPDATE portfolio_project..NashvilleHousing		
 SET sale_date_formated = CONVERT(date, SaleDate);

 SELECT sale_date_formated 
 FROM portfolio_project..NashvilleHousing

 ----------------------------------------------------------------------------------------------------------------------------------------
 -- Populate Property Address data
 SELECT a.ParcelID, b.ParcelID, a.PropertyAddress, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
 FROM portfolio_project..NashvilleHousing AS a
 JOIN portfolio_project..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
 WHERE a.PropertyAddress IS NULL

 -- The query below update all empty property address fields with addresses that have the same parcelID 

 UPDATE a
 SET PropertyAddress =  ISNULL(a.PropertyAddress, b.PropertyAddress)
 FROM portfolio_project..NashvilleHousing AS a
 JOIN portfolio_project..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
 WHERE a.PropertyAddress IS NULL

----------------------------------------------------------------------------------------------------------------------------------------

-- Breaking Address columns into smaller labels (address, city, state)
-- Starting with property address
SELECT PropertyAddress
FROM portfolio_project..NashvilleHousing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS city
FROM portfolio_project..NashvilleHousing;

ALTER TABLE portfolio_project..NashvilleHousing
ADD property_address nvarchar(255),
 property_city nvarchar(255);

UPDATE portfolio_project..NashvilleHousing
SET property_address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
	property_city =  SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

SELECT property_address, property_city
FROM portfolio_project..NashvilleHousing

--Let's split owner address as well

SELECT OwnerAddress
FROM portfolio_project..NashvilleHousing;

SELECT PARSENAME(REPLACE(OwnerAddress,',','.'), 3) AS address
, PARSENAME(REPLACE(OwnerAddress,',','.'), 2) AS city
, PARSENAME(REPLACE(OwnerAddress,',','.'), 1) AS state
FROM portfolio_project..NashvilleHousing;

ALTER TABLE	portfolio_project..NashvilleHousing
ADD owner_address nvarchar(255),
	owner_city nvarchar(255),
	owner_state nvarchar(255);

UPDATE portfolio_project..NashvilleHousing
SET owner_address = PARSENAME(REPLACE(OwnerAddress,',','.'), 3),
	owner_city = PARSENAME(REPLACE(OwnerAddress,',','.'), 2),
	owner_state = PARSENAME(REPLACE(OwnerAddress,',','.'), 1);

SELECT owner_address, owner_city, owner_state
FROM portfolio_project..NashvilleHousing;

----------------------------------------------------------------------------------------------------------------------------------------
-- Change Y and N in SoldAsVacant as Yes and No respectively
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM portfolio_project..NashvilleHousing
GROUP BY SoldAsVacant;

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM portfolio_project..NashvilleHousing;

UPDATE portfolio_project..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END;
----------------------------------------------------------------------------------------------------------------------------------------
-- Remove duplicates
WITH row_num_CTE
AS
(
SELECT *, 
ROW_NUMBER() OVER (
PARTITION BY ParcelID,
			PropertyAddress,
			OwnerAddress,
			SaleDate,
			LegalReference
			ORDER BY UniqueID
			) AS row_num
FROM portfolio_project..NashvilleHousing
)
SELECT *
FROM row_num_CTE 
WHERE row_num = 1

----------------------------------------------------------------------------------------------------------------------------------------
-- Delete unused columns 

ALTER TABLE portfolio_project..NashvilleHousing
DROP COLUMN 
