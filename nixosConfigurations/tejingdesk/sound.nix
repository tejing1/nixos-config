{
  # Enable pulseaudio
  services.pulseaudio.enable = true;
  services.pulseaudio.support32Bit = true;

  # Disable pipewire. It's now on by default when X is configured, and I don't want to switch just yet.
  services.pipewire.enable = false;

  # Really doesn't seem like it should be on by default. It's not that big, but still...
  services.speechd.enable = false;
}
