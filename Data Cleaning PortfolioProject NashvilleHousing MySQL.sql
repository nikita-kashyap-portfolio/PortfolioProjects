# RENAME TABLE nashville_housing_data_for_data_cleaning TO nashvillehousing;

/*

Cleaning Data in SQL Queries

*/


Select *
From PortfolioProject.NashvilleHousing;



/* -------------------------------------------------------------------------------------------------------------------------- */

-- Standardize Date Format


SELECT SaleDate, STR_TO_DATE(SaleDate, '%m/%d/%Y') AS SaleDate_converted
FROM nashvillehousing
LIMIT 10;

UPDATE nashvillehousing
SET SaleDate = STR_TO_DATE(SaleDate, '%m/%d/%Y')
WHERE SaleDate REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$';


-- If it doesn't Update properly

ALTER TABLE NashvilleHousing
ADD COLUMN SaleDateConverted DATE;

UPDATE NashvilleHousing
SET SaleDateConverted = STR_TO_DATE(SaleDate, '%m/%d/%Y')
WHERE SaleDate REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$';

 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

-- Check how many PropertyAddress are missing

SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID;

-- Preview candidate addresses from other rows with same ParcelID
SELECT 
    a.ParcelID AS ParcelID_missing, 
    a.PropertyAddress AS MissingAddress,
    b.ParcelID AS ParcelID_source, 
    b.PropertyAddress AS SourceAddress
FROM NashvilleHousing a
JOIN NashvilleHousing b
    ON a.ParcelID = b.ParcelID
   AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL
  AND b.PropertyAddress IS NOT NULL;

-- Update missing PropertyAddress using another row with same ParcelID
UPDATE NashvilleHousing a
JOIN NashvilleHousing b
    ON a.ParcelID = b.ParcelID
   AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = b.PropertyAddress
WHERE a.PropertyAddress IS NULL
  AND b.PropertyAddress IS NOT NULL;

-- Verify results
SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID;



--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)
-- Split PropertyAddress into Address and City
Select *
From PortfolioProject.NashvilleHousing;

-- Add new columns
ALTER TABLE NashvilleHousing
ADD COLUMN PropertySplitAddress VARCHAR(255),
ADD COLUMN PropertySplitCity VARCHAR(255);

-- Populate Address (text before first comma)
UPDATE NashvilleHousing
SET PropertySplitAddress = TRIM(SUBSTRING_INDEX(PropertyAddress, ',', 1));

-- Populate City (text after first comma)
UPDATE NashvilleHousing
SET PropertySplitCity = TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1));

-- Split OwnerAddress into Address / City / State
-- Add new columns
ALTER TABLE NashvilleHousing
ADD COLUMN OwnerSplitAddress VARCHAR(255),
ADD COLUMN OwnerSplitCity VARCHAR(255),
ADD COLUMN OwnerSplitState VARCHAR(255);

-- Address (first part)
UPDATE NashvilleHousing
SET OwnerSplitAddress = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1));

-- City (middle part)
UPDATE NashvilleHousing
SET OwnerSplitCity = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1));

-- State (last part)
UPDATE NashvilleHousing
SET OwnerSplitState = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1));


-- Verify results

SELECT PropertyAddress, PropertySplitAddress, PropertySplitCity,
       OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM portfolioproject.nashvillehousing
LIMIT 20;


--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field


-- Review current values in SoldAsVacant column
SELECT DISTINCT SoldAsVacant, COUNT(*) AS TotalCount
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY TotalCount;

-- Preview transformation without updating data
SELECT SoldAsVacant,
       CASE
           WHEN SoldAsVacant = 'Y' THEN 'Yes'
           WHEN SoldAsVacant = 'N' THEN 'No'
           ELSE SoldAsVacant
       END AS StandardizedValue
FROM NashvilleHousing;

-- Update Y and N values to Yes and No
UPDATE NashvilleHousing
SET SoldAsVacant = CASE
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END
WHERE SoldAsVacant IN ('Y', 'N');

-- Verify standardized results
SELECT DISTINCT SoldAsVacant, COUNT(*) AS TotalCount
FROM NashvilleHousing
GROUP BY SoldAsVacant;





-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
-- Identify duplicate rows using ROW_NUMBER()
WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID,
                            PropertyAddress,
                            SalePrice,
                            SaleDate,
                            LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM NashvilleHousing
)

-- Review duplicates before deleting
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

Select *
From PortfolioProject.NashvilleHousing;




---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns


--  Review table before dropping columns
SELECT *
FROM NashvilleHousing
LIMIT 10;

-- Drop unused columns (MySQL syntax)
 ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress,
DROP COLUMN SaleDate; 


-- Verify table structure
DESCRIBE NashvilleHousing;















-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

-- =========================================================
-- Importing Data using LOAD DATA INFILE (MySQL)
--
-- More advanced and faster than manual import.
-- Requires file access permissions on the MySQL server.
-- Provided for learning and experimentation purposes.
-- =========================================================


-- ---------------------------------------------------------
-- Check MySQL secure file directory
-- MySQL allows file import only from this folder
-- ---------------------------------------------------------

/*SHOW VARIABLES LIKE 'secure_file_priv';


-- ---------------------------------------------------------
-- Select Database
-- ---------------------------------------------------------

/* USE PortfolioProject; */


-- ---------------------------------------------------------
-- Create Table (Raw Import - All Text)
-- ---------------------------------------------------------

/* CREATE TABLE IF NOT EXISTS NashvilleHousing (
    UniqueID BIGINT,
    ParcelID VARCHAR(50),
    LandUse VARCHAR(100),
    PropertySplitAddress VARCHAR(255),
    PropertySplitCity VARCHAR(100),
    SaleDateConverted DATE,
    SalePrice INT,
    LegalReference VARCHAR(100),
    SoldAsVacant ENUM('Yes','No'),
    OwnerName VARCHAR(255),
    OwnerSplitAddress VARCHAR(255),
    OwnerSplitCity VARCHAR(100),
    OwnerSplitState CHAR(2),
    Acreage DECIMAL(10,2),
    LandValue INT,
    BuildingValue INT,
    TotalValue INT,
    YearBuilt YEAR,
    Bedrooms TINYINT,
    FullBath TINYINT,
    HalfBath TINYINT
); */


-- ---------------------------------------------------------
-- Using LOAD DATA INFILE (Equivalent to BULK INSERT)
-- ---------------------------------------------------------

/* LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/NashvilleHousing.csv'
INTO TABLE NashvilleHousing
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; */


-- ---------------------------------------------------------
-- Verify Imported Data
-- ---------------------------------------------------------

/* SELECT *
FROM NashvilleHousing
LIMIT 10; */