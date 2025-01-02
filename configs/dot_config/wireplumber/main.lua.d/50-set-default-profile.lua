-- Set the default profile for a specific audio card
table.insert(alsa_monitor.rules, {
  matches = {
    {
      { "node.name", "equals", "alsa_card.pci-0000_00_1f.3" },
    },
  },
  apply_properties = {
    ["device.profile"] = "HiFi",
  },
})

