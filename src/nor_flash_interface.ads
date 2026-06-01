with Nor_Flash_Types;
with MT;
with System.Storage_Elements; use System.Storage_Elements;

--  Nor_Flash_Interface is a convenience aggregation over Nor_Flash_Control
--  and Nor_Flash_Data.  It accepts a single set of Bus_* formals and
--  exposes the full NOR flash operation surface through one instantiation.
--
--  For applications that need only control-plane or data-plane operations,
--  instantiate Nor_Flash_Control or Nor_Flash_Data directly instead.

generic
   type Device is limited private;

   --  Send a command byte with no address and no data payload.
   --  Handles CS assertion/release internally.
   with procedure Bus_Command
     (Dev : in out Device;
      Cmd :        MT.UInt8);

   --  Send a command byte followed by a 24-bit address, no data payload.
   --  Handles CS assertion/release internally.
   with procedure Bus_Command_Address
     (Dev  : in out Device;
      Cmd  :        MT.UInt8;
      Addr :        Nor_Flash_Types.Nor_Address);

   --  Send READ_STATUS (0x05) and return SR1.
   --  Handles CS assertion/release internally.
   with procedure Bus_Read_Status
     (Dev    : in out Device;
      Status :    out MT.UInt8);

   --  Send a command byte and read a data payload, no address phase.
   --  Handles CS assertion/release internally.
   with procedure Bus_Command_Read
     (Dev  : in out Device;
      Cmd  :        MT.UInt8;
      Data :    out Storage_Array);

   --  Write a data payload to flash at Addr.
   --  Handles CS assertion/release internally.
   with procedure Bus_Write
     (Dev          : in out Device;
      Cmd          :        MT.UInt8;
      Addr         :        Nor_Flash_Types.Nor_Address;
      Dummy_Cycles :        Natural;
      Data         :        Storage_Array);

   --  Read a data payload from flash at Addr.
   --  Handles CS assertion/release internally.
   with procedure Bus_Read
     (Dev          : in out Device;
      Cmd          :        MT.UInt8;
      Addr         :        Nor_Flash_Types.Nor_Address;
      Dummy_Cycles :        Natural;
      Data         :    out Storage_Array);

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
   with procedure Driver_Write_Status
     (Dev : in out Device;
      SR1 :        MT.UInt8;
      SR2 :        MT.UInt8);

package Nor_Flash_Interface is

   --  Validate JEDEC identity, configure QE if Transfer = Quad,
   --  and release the device from deep power-down if sleeping.
   --  Must be called before any other operation.
   --  Raises Nor_Error   if the device is not recognised.
   --  Raises Nor_Timeout if QE programming does not complete in time.
   procedure Open
     (Dev : in out Device);

   --  Put the device into deep power-down.
   --  Call Open again before any further operations.
   procedure Close
     (Dev : in out Device);

   --  Software reset via 0x66 / 0x99 sequence.
   --  Returns device to power-on default state.
   --  Caller must call Open again before any further operations.
   procedure Reset
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

   --  Write Buf to flash at Addr.
   --  Buf must not cross a page boundary; raises Nor_Error if violated.
   --  Target range must already be erased (all 0xFF).
   --  Raises Nor_Timeout if WIP does not clear in time.
   procedure Write_Page
     (Dev  : in out Device;
      Addr :        Nor_Flash_Types.Nor_Address;
      Buf  :        Storage_Array);

   --  Read Buf'Length bytes from flash starting at Addr.
   --  Uses fast-read command (0x0B) with one dummy cycle.
   --  No erase precondition -- reads are unconditionally valid.
   procedure Read
     (Dev  : in out Device;
      Addr :        Nor_Flash_Types.Nor_Address;
      Buf  :    out Storage_Array);

end Nor_Flash_Interface;