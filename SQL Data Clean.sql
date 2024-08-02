/* 
Cleaning Data in SQL
*/

-- Convert SaleDate Format

SELECT *
FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate;

sp_rename 'NashvilleHousing.SaleDateConverted', 'SaleDate', 'COLUMN'



----------------------------------------
-- Populate Property Address Data

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

SELECT *
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress IS NULL



---------------------------------------------------------------------------
-- Breaking out Address into individual columns (Address, City, State)

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing


ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)


ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))



SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address
FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerPropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerPropertySplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)


ALTER TABLE NashvilleHousing
ADD OwnerPropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerPropertySplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerPropertySplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerPropertySplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


SELECT *
FROM PortfolioProject..NashvilleHousing



-------------------------------------------------------------
-- Change Y and N to Yes and No in "SoldAsVacant" field

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM PortfolioProject..NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END



--------------------------
-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *
, ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
						ORDER BY UniqueID) AS row_num
FROM PortfolioProject..NashvilleHousing)


DELETE
FROM RowNumCTE
WHERE row_num > 1




-------------------------------
-- Delete Unused Columns


ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress
