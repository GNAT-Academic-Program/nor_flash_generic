package body Nor_Flash_Control is

   use type MT.UInt8;
   use type MT.UInt32;
   use type Nor_Flash_Types.Manufacturer_Id;
   use type Nor_Flash_Types.Memory_Type_Id;
   use type Nor_Flash_Types.Capacity_Code;

   --  Universal NOR flash command bytes
   CMD_WREN         : constant MT.UInt8 := 16#06#;  --  Write Enable
   CMD_JEDEC_ID     : constant MT.UInt8 := 16#9F#;  --  Read JEDEC ID (3 bytes)
   CMD_RESET_ENABLE : constant MT.UInt8 := 16#66#;  --  Enable Reset
   CMD_RESET        : constant MT.UInt8 := 16#99#;  --  Reset Device
   CMD_POWER_DOWN   : constant MT.UInt8 := 16#B9#;  --  Deep Power-Down
   CMD_RELEASE_PD   : constant MT.UInt8 := 16#AB#;  --  Release Power-Down
   CMD_ERASE_SECTOR : constant MT.UInt8 := 16#20#;  --  Sector Erase  (4K)
   CMD_ERASE_BLOCK  : constant MT.UInt8 := 16#D8#;  --  Block Erase  (64K)
   CMD_ERASE_CHIP   : constant MT.UInt8 := 16#60#;  --  Chip Erase

   --  Status register bit masks
   WIP_BIT : constant MT.UInt8 := 16#01#;  --  Write In Progress (SR1)
   QE_BIT  : constant MT.UInt8 := 16#02#;  --  Quad Enable       (SR2)

   --  W25Q128 sector erase: typical 45 ms, max 400 ms.
   --  The polling loop can run much faster than the SPI wire speed (the HAL
   --  may return before the SPI FIFO has fully drained), so the iteration
   --  count must be generous.  50_000_000 gives ~25 s of budget at 0.5 µs/
   --  poll, safely covering the 400 ms worst-case sector erase.
   WIP_Poll_Limit  : constant Natural := 50_000_000;
   tRES_Poll_Limit : constant Natural :=       100;  --  W25Q128 tRES <= 3 us

   ------------------------------------------------------------
   --  Private helpers
   ------------------------------------------------------------

   procedure Write_Enable (Dev : in out Device) is
   begin
      Bus_Command (Dev, CMD_WREN);
   end Write_Enable;

   procedure Poll_WIP (Dev : in out Device) is
      SR         : MT.UInt8;
      Poll_Count : Natural := 0;
   begin
      loop
         Bus_Read_Status (Dev, SR);
         exit when (SR and WIP_BIT) = 0;
         delay 0.01;
      end loop;
   end Poll_WIP;

   procedure Ensure_QE (Dev : in out Device) is
      SR2 : MT.UInt8;
   begin
      SR2 := Driver_Read_SR2 (Dev);
      if (SR2 and QE_BIT) /= 0 then
         return;
      end if;
      Write_Enable (Dev);
      Driver_Write_Status (Dev, SR1 => 16#00#, SR2 => SR2 or QE_BIT);
      Poll_WIP (Dev);
   end Ensure_QE;

   ----------
   -- Init --
   ----------

   procedure Init (Dev : in out Device) is
      Cfg    : constant Nor_Flash_Types.Nor_Config := Driver_Config (Dev);
      Raw    : Storage_Array (1 .. 3);
      Actual : Nor_Flash_Types.Nor_Id;
      use type Nor_Flash_Types.Transfer_Mode;
   begin
      Bus_Command_Read (Dev, CMD_JEDEC_ID, Raw);

      Actual := (Manufacturer => Nor_Flash_Types.Manufacturer_Id (Raw (1)),
                 Memory_Type  => Nor_Flash_Types.Memory_Type_Id  (Raw (2)),
                 Capacity     => Nor_Flash_Types.Capacity_Code   (Raw (3)));

      --  if Actual.Manufacturer /= Cfg.Id.Manufacturer or else
      --     Actual.Memory_Type  /= Cfg.Id.Memory_Type  or else
      --     Actual.Capacity     /= Cfg.Id.Capacity
      --  then
      --     raise Nor_Flash_Types.Nor_Error;
      --  end if;

      if Cfg.Transfer = Nor_Flash_Types.Quad then
         Ensure_QE (Dev);
      end if;
   end Init;

   -----------
   -- Reset --
   -----------

   procedure Reset (Dev : in out Device) is
   begin
      Bus_Command (Dev, CMD_RESET_ENABLE);
      Bus_Command (Dev, CMD_RESET);
   end Reset;

   -----------
   -- Sleep --
   -----------

   procedure Sleep (Dev : in out Device) is
   begin
      Bus_Command (Dev, CMD_POWER_DOWN);
   end Sleep;

   ----------
   -- Wake --
   ----------

   procedure Wake (Dev : in out Device) is
      SR         : MT.UInt8;
      Poll_Count : Natural := 0;
   begin
      Bus_Command (Dev, CMD_RELEASE_PD);
      loop
         Bus_Read_Status (Dev, SR);
         exit when (SR and WIP_BIT) = 0;
         delay 0.01;
      end loop;
   end Wake;

   ------------------
   -- Erase_Sector --
   ------------------

   procedure Erase_Sector
     (Dev : in out Device;
      Idx : Nor_Flash_Types.Sector_Index)
   is
      Addr : constant Nor_Flash_Types.Nor_Address :=
        Nor_Flash_Types.Nor_Address (Idx)
          * Nor_Flash_Types.Nor_Address
              (Nor_Flash_Types.Erase_Granularity'Enum_Rep
                 (Nor_Flash_Types.Sector_4K));
   begin
      Write_Enable (Dev);
      Bus_Command_Address (Dev, CMD_ERASE_SECTOR, Addr);
      Poll_WIP (Dev);
   end Erase_Sector;

   -----------------
   -- Erase_Block --
   -----------------

   procedure Erase_Block
     (Dev : in out Device;
      Idx : Nor_Flash_Types.Block_Index)
   is
      Addr : constant Nor_Flash_Types.Nor_Address :=
        Nor_Flash_Types.Nor_Address (Idx)
          * Nor_Flash_Types.Nor_Address
              (Nor_Flash_Types.Erase_Granularity'Enum_Rep
                 (Nor_Flash_Types.Block_64K));
   begin
      Write_Enable (Dev);
      Bus_Command_Address (Dev, CMD_ERASE_BLOCK, Addr);
      Poll_WIP (Dev);
   end Erase_Block;

   ----------------
   -- Erase_Chip --
   ----------------

   procedure Erase_Chip (Dev : in out Device) is
   begin
      Write_Enable (Dev);
      Bus_Command (Dev, CMD_ERASE_CHIP);
      Poll_WIP (Dev);
   end Erase_Chip;

end Nor_Flash_Control;