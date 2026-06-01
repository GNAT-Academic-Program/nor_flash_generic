with MT;

--  TODO: 4-byte addressing (chips > 128 Mbit, JESD216B DWORD 16)
--  Nor_Address is already UInt32 -- Send_Address currently sends only 3 bytes
--  (24-bit). For chips > 128 Mbit, add an addressing mode flag to
--  Nor_Config or a formal boolean to the device driver.

package Nor_Flash_Types is

   Nor_Error       : exception;  --  programming error, bad config, unrecoverable
   Nor_Unsupported : exception;  --  operation not supported by this device
   Nor_Timeout     : exception;  --  device did not complete in time

   subtype Nor_Address is MT.UInt32;
   subtype Nor_Size    is MT.UInt32;

   type Page_Index   is new MT.UInt32;
   type Sector_Index is new MT.UInt32;
   type Block_Index  is new MT.UInt32;

   type Page_Size is new MT.UInt16;

   type Nor_Status is (Ready, Busy, Write_Protected, Error);

   type Protection_State is
     (Unprotected, Software_Protected, Hardware_Protected);

   --  SPI/QSPI transfer width.
   type Transfer_Mode is (Single, Dual, Quad);

   --  Erase unit granularity.
   --  Representation value is the erase unit size in bytes.
   --  Chip erase has no meaningful byte size; sentinel value 0.
   type Erase_Granularity is
     (Chip, Sector_4K, Block_32K, Block_64K);

   for Erase_Granularity use
     (Chip      =>      0,
      Sector_4K =>  4_096,
      Block_32K => 32_768,
      Block_64K => 65_536);

   --  JEDEC 3-byte ID, read via command 0x9F.
   --  Manufacturer, Memory_Type, and Capacity encoding are JEDEC-standardized.
   type Manufacturer_Id is new MT.UInt8;
   type Memory_Type_Id  is new MT.UInt8;
   type Capacity_Code   is new MT.UInt8;

   type Nor_Id is record
      Manufacturer : Manufacturer_Id;
      Memory_Type  : Memory_Type_Id;
      Capacity     : Capacity_Code;
   end record;

   --  Full device configuration.
   type Nor_Config is record
      Total_Size  : Nor_Size;
      Page_Size   : Nor_Flash_Types.Page_Size;
      Erase_Gran  : Erase_Granularity;
      Transfer    : Transfer_Mode;
      Protection  : Protection_State;
      Id          : Nor_Id;
   end record;

end Nor_Flash_Types;