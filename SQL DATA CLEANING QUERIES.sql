

--Nashville Housing  Dataset Cleanup on SQL Server
  /* Cleaning Data in SQL Queries */
     

  Select *
  From PortFolio_Project..nashvillehousing

  -----------------------------------------------------------------------------------------------------------------------------------------------------

--1 Standardize date format


  Select SaleDate, CONVERT(date, saledate) 
  From  PortFolio_Project..nashvillehousing

  Update nashvillehousing
  Set SaleDate= CONVERT(date, saledate) 
  
  -- incase it doesnt Update properly try the method below

  ALTER TABLE nashvillehousing
  add saledateconverted date;

  Update nashvillehousing
  set saledateconverted = CONVERT(date, saledate)

  --Rerun to confirm the changes

  Select saledateconverted 
  From  PortFolio_Project..nashvillehousing
  ---------------------------------------------------------------------------------------------------------------------------------------------------
  --2 Populate property address data by updating null values

 Select PropertyAddress
  from PortFolio_Project..nashvillehousing
  --where PropertyAddress is null
   order by ParcelID  --findout that parcelID and propertyaddress can be populated as same


 --Now we do a self join. we joined the table to itself where the parcel id is the same but not in the same row

  Select a. parcelid, a.propertyaddress, b.parcelid, b.propertyaddress
  From PortFolio_Project..nashvillehousing a
        JOIN PortFolio_Project..nashvillehousing b 
  On a.parcelID= b.parcelID 
       AND a.uniqueID <> b.uniqueID
  Where a.PropertyAddress is null



--Now this query uses ISNULL to populate the column that has Null values

 Select a. parcelid, a.propertyaddress, b.parcelid, b.propertyaddress, ISNULL(a.propertyaddress, b.propertyaddress)
  From PortFolio_Project..nashvillehousing a
  JOIN PortFolio_Project..nashvillehousing b 
  On a.parcelID= b.parcelID 
  AND a.uniqueID <> b.uniqueID
  Where a.PropertyAddress is null


  -- To Update the PropertyAddress Null Columns

 Update a 
  set propertyaddress =  ISNULL(a.propertyaddress, b.propertyaddress)
  from PortFolio_Project..nashvillehousing a
JOIN PortFolio_Project..nashvillehousing b 
  On a.parcelID= b.parcelID 
 AND a.uniqueID <> b.uniqueID 
  where a.PropertyAddress is null
  
-- Once the update query has been run, 
--go back and check the last query to see that there are no longer null propertyaddress and brings out an empty result


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3 The next cleaning stage is to break out propertyaddress into individual columns(address, city, state) using substring and charindex

  Select PropertyAddress
  From PortFolio_Project..nashvillehousing
  --Where PropertyAddress is not null
 -- Order by ParcelID

 Select 
 SUBSTRING(propertyaddress, 1, CHARINDEX (',', PropertyAddress) -1) as address
 , SUBSTRING(propertyaddress, CHARINDEX (',' , PropertyAddress)  +1, len (propertyaddress) ) as address

  from PortFolio_Project..nashvillehousing

  --Now you create 2 new column(run it one after the other)

  ALTER TABLE nashvillehousing
  add propertysplitaddress nvarchar(255);

  Update nashvillehousing
  SET propertysplitaddress = SUBSTRING(propertyaddress, 1, CHARINDEX (',', PropertyAddress) -1)

  ALTER TABLE nashvillehousing
  add  propertysplitcity nvarchar(255);

  Update nashvillehousing
   SET propertysplitcity =  SUBSTRING(propertyaddress, CHARINDEX (',' , PropertyAddress)  +1, len (propertyaddress) )

  Select *
  From PortFolio_Project..nashvillehousing
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---	--4 Breaking out OWNERNAME column into individual columns(address, city, state) using PARSENAME

   Select OwnerAddress
    From PortFolio_Project..nashvillehousing
	--where  OwnerAddress is  null

--parsename is useful with periods(.) and our data is in comma(,) we have to replace the comma with periods.

Select 
PARSENAME(Replace(OwnerAddress, ',' , '.') , 3)
, PARSENAME(Replace(OwnerAddress, ',' , '.') , 2)
,PARSENAME(Replace(OwnerAddress, ',' , '.') , 1)
From PortFolio_Project..nashvillehousing 

-- Now update the columns
ALTER TABLE nashvillehousing
  add ownersplitaddress nvarchar(255);

  Update nashvillehousing
  SET ownersplitaddress =PARSENAME(Replace(OwnerAddress, ',' , '.') , 3)

 ALTER TABLE nashvillehousing
  add  ownersplitcity nvarchar(255);

  Update nashvillehousing
  SET  ownersplitcity =  PARSENAME(Replace(OwnerAddress, ',' , '.') , 2)

  ALTER TABLE nashvillehousing
  add  ownersplitstate nvarchar(255);

  Update nashvillehousing
 SET  ownersplitstate = PARSENAME(Replace(OwnerAddress, ',' , '.') , 1)  

   Select *
   From PortFolio_Project..nashvillehousing

------	---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---	--5 Changing Y and N to YES and NO in " Sold as vacant"  column using the CASE statement

	Select DISTINCT  (SoldAsVacant), Count (SoldAsVacant)
    From PortFolio_Project..nashvillehousing
	Group by (SoldAsVacant)
	Order by 2


	Select SoldAsVacant
	, CASE When SoldAsVacant = 'Y' then 'yes'
	                When SoldAsVacant = 'N' then 'No'
			         ELSE SoldAsVacant
			       END
   From PortFolio_Project..nashvillehousing

	 Update nashvillehousing
     SET  SoldAsVacant =CASE when SoldAsVacant = 'Y' then 'yes'
	          When SoldAsVacant = 'N' then 'No'
			 ELSE SoldAsVacant
		     END

--Rerun to confirm changes
	select distinct (SoldAsVacant),count (SoldAsVacant)
    from PortFolio_Project..nashvillehousing
	group by (SoldAsVacant)
	order by 2
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--6 Removing duplicates  
WITH RownumCTE as (
	 Select *,
	               ROW_NUMBER() Over (
                   Partition by parcelid,
	               propertyAddress,
		           saledate,
		           saleprice,
		           legalreference
		 Order by  uniqueID
		                ) row_num
    
	From PortFolio_Project..nashvillehousing
		   --order by ParcelID
		   )
		   Select *
		   From RownumCTE
		   Where row_num > 1
		   Order by PropertyAddress

    Select *
    From PortFolio_Project..nashvillehousing	
	
-------------------------------------------------------------------------------------------------------------------------------------------------------------------	--------------------	 
		 --Delete unused columns
		 Select *
	     From PortFolio_Project..nashvillehousing	


		ALTER TABLE  PortFolio_Project..nashvillehousing
		DROP COLUMN propertyaddress, saledate, owneraddress, taxdistrict
		



