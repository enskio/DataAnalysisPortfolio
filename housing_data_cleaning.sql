/*

Cleaning data in SQL Queries

*/
SELECT * FROM portfolioproject.nashvillehousing;

-- Convert all the empty string to NULL in the table
UPDATE NashvilleHousing
SET 
	UniqueID = CASE UniqueID WHEN "" THEN NULL ELSE UniqueID END,
    ParcelID = CASE ParcelID WHEN "" THEN NULL ELSE ParcelID END,
    LandUse = CASE LandUse WHEN "" THEN NULL ELSE LandUse END,
    PropertyAddress = CASE PropertyAddress WHEN "" THEN NULL ELSE PropertyAddress END,
    -- SaleDate = CASE SaleDate WHEN "" THEN NULL ELSE SaleDate END,
    SalePrice = CASE SalePrice WHEN "" THEN NULL ELSE SalePrice END,
	LegalReference = CASE LegalReference WHEN "" THEN NULL ELSE LegalReference END,
    SoldAsVacant = CASE SoldAsVacant WHEN "" THEN NULL ELSE SoldAsVacant END,
    OwnerName = CASE OwnerName WHEN "" THEN NULL ELSE OwnerName END,
    OwnerAddress = CASE OwnerAddress WHEN "" THEN NULL ELSE OwnerAddress END,
    Acreage = CASE Acreage WHEN "" THEN NULL ELSE Acreage END,
    TaxDistrict = CASE TaxDistrict WHEN "" THEN NULL ELSE TaxDistrict END,
    LandValue = CASE LandValue WHEN "" THEN NULL ELSE LandValue END,
    BuildingValue = CASE BuildingValue WHEN "" THEN NULL ELSE BuildingValue END,
    TotalValue = CASE TotalValue WHEN "" THEN NULL ELSE TotalValue END,
    YearBuilt = CASE YearBuilt WHEN "" THEN NULL ELSE YearBuilt END,
    Bedrooms = CASE Bedrooms WHEN "" THEN NULL ELSE Bedrooms END,
    FullBath = CASE FullBath WHEN "" THEN NULL ELSE FullBath END,
    HalfBath = CASE HalfBath WHEN "" THEN NULL ELSE HalfBath END;
    -- SaleDateConverted = CASE SaleDateConverted WHEN "" THEN NULL ELSE SaleDateConverted END;
    

-- Standardise Date Format to only include date instead of date and time

-- UPDATE doesnt work, so we need to use ALTER TABLE to create a new coloum and SET the value 
SELECT SaleDate, CAST(SaleDate AS date)
FROM portfolioproject.nashvillehousing;

UPDATE NashvilleHousing
SET SaleDate = CAST(SaleDate AS date);


-- Add new column 
ALTER TABLE NashvilleHousing
ADD SaleDateConverted date;

-- Add casted date value to new column
UPDATE NashvilleHousing
SET SaleDateConverted = CAST(SaleDate AS date);


------------------------------------------------------------------------------------------------


-- Populate Property Address (some property address has null/no value)

-- the same ParcelID will have the same address
SELECT house1.ParcelID, house1.PropertyAddress, house2.ParcelID, house2.PropertyAddress
FROM portfolioproject.nashvillehousing house1
JOIN portfolioproject.nashvillehousing house2
	ON house1.ParcelID = house2.ParcelID
    AND house1.UniqueID != house2.UniqueID
WHERE house1.PropertyAddress IS NULL;

-- this query doesnt work in MySQL, need to make a temp table
UPDATE portfolioproject.nashvillehousing 
SET PropertyAddress = (
SELECT 
IFNULL(house1.PropertyAddress, house2.PropertyAddress)
-- COALESCE(house1.PropertyAddress, house2.PropertyAddress)
FROM (SELECT * FROM portfolioproject.nashvillehousing) AS house1 
JOIN portfolioproject.nashvillehousing house2
	ON house1.ParcelID = house2.ParcelID
    AND house1.UniqueID != house2.UniqueID
WHERE house1.PropertyAddress IS NULL
);

-- Temp table method
DROP TABLE IF EXISTS NashvilleHousing_Temp;
CREATE TEMPORARY TABLE NashvilleHousing_Temp AS
(
SELECT house1.ParcelID AS parcel1, house1.PropertyAddress AS address1, house2.UniqueID AS unique2, house2.ParcelID AS parcel2, house2.PropertyAddress AS address2
FROM portfolioproject.nashvillehousing house1
JOIN portfolioproject.nashvillehousing house2
	ON house1.ParcelID = house2.ParcelID
    AND house1.UniqueID != house2.UniqueID
WHERE house1.PropertyAddress IS NULL
);

UPDATE NashvilleHousing d
SET PropertyAddress = (
	SELECT t.address2
    FROM NashvilleHousing_Temp t
    WHERE t.parcel2 = d.ParcelID
    AND t.unique2 != d.UniqueID
    LIMIT 1
)
WHERE PropertyAddress IS NULL;
DROP TEMPORARY TABLE IF EXISTS NashvilleHousing_Temp;



------------------------------------------------------------------------------------------------


-- Breaking out PropertyAddress into individual columns (address, city, state)

-- not working in mysql
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1 ) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM portfolioproject.nashvillehousing;

-- working query in mysql
SELECT
TRIM(SUBSTRING_INDEX(PropertyAddress, ',', 1)) AS Address,
TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1)) AS City
FROM portfolioproject.nashvillehousing;

-- Add new columns and insert value 
ALTER TABLE nashvillehousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE nashvillehousing
SET PropertySplitAddress = TRIM(SUBSTRING_INDEX(PropertyAddress, ',', 1));

ALTER TABLE nashvillehousing
ADD PropertySplitCity Nvarchar(255);

UPDATE nashvillehousing
SET PropertySplitCity = TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1));



------------------------------------------------------------------------------------------------

-- Breaking up OwnerAddress

-- output street
SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 1), ',', -1)) AS extracted_street
FROM nashvillehousing;

-- output city
SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1)) AS extracted_city
FROM nashvillehousing;

-- output state
SELECT TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1)) AS extracted_state
FROM nashvillehousing;



ALTER TABLE nashvillehousing
ADD OwnerAddressStreet Nvarchar(255),
ADD OwnerAddressCity Nvarchar(255),
ADD OwnerAddressState Nvarchar(255);

UPDATE nashvillehousing
SET OwnerAddressStreet = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 1), ',', -1))
, OwnerAddressCity = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1))
, OwnerAddressState = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1));




-- SELECT SUBSTRING_INDEX(SUBSTRING_INDEX('123,456,789', ',', -2), ',', 1) AS extracted_portion;
-- SELECT SUBSTRING_INDEX('123,456,789', ',', 2);


------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "SoldAsVacant" column

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS NumberOfOccurrance
FROM nashvillehousing
GROUP BY SoldAsVacant
ORDER BY NumberOfOccurrance;


SELECT SoldAsVacant,
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
    END AS SoldAsVacantModified
FROM nashvillehousing;


UPDATE nashvillehousing
SET SoldAsVacant = (
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
    END
);

------------------------------------------------------------------------------------------------

-- Remove duplicates from the table

-- Find duplicated rows (assuming each row should have unique combination of ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference)
WITH RowNumCTE AS (
	SELECT *,
		ROW_NUMBER() OVER (
			PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
			ORDER BY UniqueID
		) row_num
	FROM nashvillehousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1;


-- Delete duplicated rows
-- MySQL doesnt support DELETE while referencing a CTE, so need to use temporary table instead 
WITH RowNumCTE AS (
	SELECT *,
		ROW_NUMBER() OVER (
			PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
			ORDER BY UniqueID
		) row_num
	FROM nashvillehousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1;


-- temp table method
CREATE TEMPORARY TABLE TempTable AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM nashvillehousing
);

DELETE FROM nashvillehousing
WHERE (ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference, UniqueID) IN (
    SELECT ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference, UniqueID
    FROM TempTable
    WHERE row_num > 1
);

DROP TEMPORARY TABLE TempTable;

------------------------------------------------------------------------------------------------

-- Delete unused columns

ALTER TABLE nashvillehousing
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress,
DROP COLUMN SaleDate;

SELECT *
FROM nashvillehousing;











