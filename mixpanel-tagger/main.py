from mixpanel import Mixpanel
import os

mp = Mixpanel(os.get_env("PROJECT_TOKEN"))
