with Nor_Flash_Types;
with MT;
with System.Storage_Elements; use System.Storage_Elements;

generic
   type Device is limited private;

   --  Send a command byte with no address and no data payload.
   --  Handles CS assertion/release internally.
   --  Examples: WREN (0x06), RESET_ENABLE (0x66), RESET (0x99),
   --            POWER_DOWN (0xB9), RELEASE_PD (0xAB), CHIP_ERASE (0x60).
   with procedure Bus_Command
     (Dev : in out Device;
      Cmd :        MT.UInt8);

   --  Send a command byte followed by a 24-bit address, no data payload.
   --  Handles CS assertion/release internally.
   --  Examples: SECTOR_ERASE (0x20), BLOCK_ERASE (0xD8).
   with procedure Bus_Command_Address
     (Dev  : in out Device;
      Cmd  :        MT.UInt8;
      Addr :        Nor_Flash_Types.Nor_Address);

   --  Send READ_STATUS (0x05) and return SR1.
   --  Handles CS assertion/release internally.
   with procedure Bus_Read_Status
     (Dev    : in out Device;
      Status :    out MT.UInt8);

   --  Read a data payload after a command byte, no address phase.
   --  Used for JEDEC ID (0x9F): Cmd = 0x9F, Data = 3 bytes out.
   --  Handles CS assertion/release internally.
   with procedure Bus_Command_Read
     (Dev  : in out Device;
      Cmd  :        MT.UInt8;
      Data :    out Storage_Array);

   --  Returns the full device configuration including expected JEDEC ID,
   --  transfer mode, erase granularity, and geometry.
   with function Driver_Config
     (Dev : Device) return Nor_Flash_Types.Nor_Config;

   --  Read SR2 (status register 2).
   --  For devices without SR2, provide a stub returning 0.
   --  Only called when Driver_Config returns Transfer = Quad.
   with function Driver_Read_SR2
     (Dev : Device) return MT.UInt8;

   --  Write SR1 and SR2 atomically.
   --  Only called when Transfer = Quad and QE is not already set.
   --  Vendor note: Winbond W25Q128 uses command 0x01 + SR1 + SR2
   --  in a single CS-framed transaction.
   with procedure Driver_Write_Status
     (Dev : in out Device;
      SR1 :        MT.UInt8;
      SR2 :        MT.UInt8);

package Nor_Flash_Control is

   --  Verify device presence via JEDEC ID (command 0x9F) and validate
   --  against Driver_Config.Id.  If Transfer = Quad, reads SR2 and sets
   --  the QE bit if not already programmed.
   --  Must be called before any other operation.
   --  Raises Nor_Error   if the device does not respond or ID mismatch.
   --  Raises Nor_Timeout if QE programming does not complete in time.
   procedure Init
     (Dev : in out Device);

   --  Software reset via 0x66 / 0x99 sequence.  Returns device to
   --  power-on default state, including clearing volatile QE if applicable.
   --  Caller must call Init again before any further operations.
   --  Raises Nor_Timeout if the device does not complete in time.
   procedure Reset
     (Dev : in out Device);

   --  Enter deep power-down mode (command 0xB9).
   --  Device ignores all commands except Wake.
   procedure Sleep
     (Dev : in out Device);

   --  Release from deep power-down (command 0xAB) and poll until ready.
   --  Raises Nor_Timeout if the device does not acknowledge within tRES.
   procedure Wake
     (Dev : in out Device);

   --  Erase the 4K sector at Idx.
   --  Raises Nor_Timeout if the device does not complete in time.
   procedure Erase_Sector
     (Dev : in out Device;
      Idx : Nor_Flash_Types.Sector_Index);

   --  Erase the 64K block at Idx.
   --  Raises Nor_Timeout if the device does not complete in time.
   procedure Erase_Block
     (Dev : in out Device;
      Idx : Nor_Flash_Types.Block_Index);

   --  Full chip erase.  Slow -- can take tens of seconds on large devices.
   --  Raises Nor_Timeout if the device does not complete in time.
   procedure Erase_Chip
     (Dev : in out Device);

end Nor_Flash_Control;