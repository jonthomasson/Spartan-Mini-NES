I've been a fan of the original NES from childhood. To me it was a magical system, which captured my interest for the first time one Christmas morning. As an adult, I still have fond memories of that console. Part of the impetus for this project came from those childhood memories.  
  
The Spartan Mini NES, as its name implies, has at its foundation a [Spartan Mini FPGA board](https://github.com/jonthomasson/SpartanMini). The Spartan Mini is a development board built around the Spartan 6 FPGA by Xilinx. To facilitate the transfer of games from the SD card to the FPGA, I'm using a Parallax Propeller, which is connected to the FPGA with a serial link.

At its heart, this project relies on the Spartan 6 FPGA by Xilinx. I'm using the TQFP 144 pin version for ease of soldering. To facilitate breaking out all of the pins and getting the project up and running quickly, I've used the  [Spartan Mini FPGA board](https://github.com/jonthomasson/SpartanMini), as well as the perfboard shield.

For the NES core I chose  [this one developed by Brian Bennett](https://github.com/brianbennett/fpga_nes). I first prototyped the project as much as possible on a breadboard, working out the kinks in the design until it was ready to be wired onto perfboard.

![](https://ce-forum.s3.amazonaws.com/original/1X/7c13617722c302d1d92f3da401a9de24ca03b5ca.jpg)

![](https://ce-forum.s3.amazonaws.com/original/1X/105fdd29481efc8f9d8a1c6d3b57805e25647b93.jpg)

Besides the Spartan Mini, the other components used for this build were:

-   The  [Adafruit 40 Pin TFT Friend](https://www.adafruit.com/product/1932)
-   The [Adafruit Mono 2.5W Class D Audio Amplifier - PAM8302](https://www.adafruit.com/product/2130)
-   The  [Adafruit Breadboard-Friendly PCB Mount Mini Speaker - 8 Ohm 0.2W](https://www.adafruit.com/product/1898?gclid=CjwKCAiAlfnUBRBQEiwAWpPA6ZmdnJprCETX1CXwhQVTNCWsY9VVICv4csFJM9_hXa4CajkE9DbYCRoCywYQAvD_BwE)
-   The [Parallax Propeller Mini](https://www.parallax.com/product/32150)

Here are the wiring diagrams I used to get the project all wired up.

**Joypad:**

![](https://lh3.googleusercontent.com/G_ijEdbCOJcArO9QVZjEJi_ETzJ7K9X18oTC9j8gPMn-yZdFrY7veoHUBWZ_b0bYjt675raKRwC6z60U3yaXcPCo3zrYOA6M-ReIpKhxFm7AN22hulfOXkBbbtJV4mr018vUCdVzo9Pgw1aOaLqB8U2qeKUFsUdsR6-X7Hx9mUewIgKWK1ZShNA6BJ1vfYi7LoKRZfIhbhh3lTurHYl2XE8VT0SYkDmfppPixj98lfIEuAp2LYojruUN2NQ50uRmHprgF8TNwEuxbm_ZKnpWEfy_e6FKRUV5oDrBxNvmmDRRKc1mgZfQNSMIXn2e667niUqG-OmBWskYQ0cQgHmLlCu0NZm6AJE5Ol3QiHfnhWxm_jUcahVfrBn_udyybWaT9fZ1W1eJfOfnUyXnfngx93I3slcs2NJtL46uXhBFufkj-aaKTIMwx07mCNHHHpV2gxFG7zOTTTVGbEs7Zssf7pC0fmJAbpvgU0AB1F-NldQlFJ_cN86WSajQhT_vmtYm1rtopaNpi5x6ynt4iy5ifg7IVwxD_0WYurtdxtWtYMh91H1TtSzZLcznwwBHrz4ZRG41sMmuBknfAi6_FP1ZBHPKHo8XNA1qENMHuz5T-kdMzfWOfXOP66Z3y8cC4QNakxFmSpRr-1EFgFOsLr3vLX6UyZ-DPKPQvA=w720-h540-no)

**Parallax Propeller and SD Card Interface:**

![](https://lh3.googleusercontent.com/67RK03zv-YHlgBzEKI64mR9WJjMG4r0vLpm7wjhhQR8B7yB2miSO8A2Wu4HD0Fiin9boylPTZT4fa4bPH4irvOwXAKCQnQfG3b-ik7cquTPi-TsFJVIk4p8_WVml8VAomyTAaNMcvD6nXj1dGUdDhf9jWh31GdssX0rBSZFq9w1PwXrbfg7GylTz5nsU0LAqUz5fNxFJUoR4J6irXo57VatSkCzm7LTSHZaWlPo-8CpH7yVJeuafDukBBCijqZ0JMSv9lY0Hfc1dmTRfzZ52YIwkr9UqM-0JRA8FWM4PXZvNgAka6kMYAEPHTxuZJFGzIjfpAindla2xL4iml6OG5-TzFEIFujEV5qQfORnXSF-rpTm-slu8oXbslmkLW5laqStv7Z1uCCEtAxDDHNioUjS0QowEGA4k_JFh1ZxhWSpZBQOPqN8v-S3hoF-02Gh_sDI3oH8sUKSxzDA0U45tgYodOJb9oe48AwDjLbR6YSJfOSriaFQdGqPXmJP3X8ZxbxqSxJhHmhteJ4L1pyNnr0S_dzyvIfGYtTvnTijur3bqrXPEAvXjRjTeVYhZNhBl5dx0HkOy3qOyjJ00otMAfYs-Jwl-BgJDzYjVQhJqvBERTBHExM52AHLOL5GE4x3e_SsEB8kAj_yArTNSbllwDrf1dUzt6Dnm9A=w800-h600-no)

**TFT Display:**

![](https://lh3.googleusercontent.com/qMa23puFFzDfIoa52lmlT6vdRjbH669SqYNUZcUXqLmA27mZ9wPoCp8MscaUO9r6tv_h1WR5ba73rJ4aDs87jXyC7wrR71w3IrZuv8W1g7zwWDlhaKjKsZ3KRMEdOHYf0c2FnVwhUPMcdtAbhkNJRZ2N2WS73mVDMIWybCkxOTKwEF-LTWAMgx_S0GkXadEwHsVCIvXaFwjX1Qbsi9zpBB1ODe944d02uLyFH9CBfawgfZGtiqaDsa-qkRF_A8ef1G2RpvE0_93E1U0oqGK0c_BkR-hA8oMBgAm_iWl0j8zJk2U9DPtgtrT4rMJeZdAbnqnLFK9qMdlTAAGNmFu2219-CP79HOPXRgFPYAvkDz4ghbYK1w7TrpvXYZ4vqnPSDLcN4QYnhNMl7VekMaxBMFKmj9N7Kwj9Ur4pAfUxPoyYGs5d2h_TI54BrFcG8CTJMqmi3tt8sP682Dsb7eII6QA7LVbx4fAGw0cxY1qDJYBVpThqjTJSW1-gbIoOlg9-qDBa6H5PgH3XkpWgYbG0NYkHmpkUrv0AYJqubJjN-WW_8rsg5Wm3vdlpcNLqABxI8_dOGHWO_K96imPojENsQT5absruA6tLwyRTUDCwW0cY7Q-vCm_DGUTZIls90KD-w4_I3ZfN5W2x2bWvbykgduQWQpTExHyHpw=w800-h600-no)

**Audio Amplifier:**

![](https://lh3.googleusercontent.com/ia3bGZmcFnsjVdncv4Nq5RC5qwPyieplkttK1VihFiz6y6kaYaGog1Onm7zzhoAGXGqddR1a1yfZaJAppGLi6ThZTWbg2cuRwA60h7KUXHqs-o4jrZDrHgH0a_PmBtlzeZctUmw5EqCzHQEwt01hofBTjU6nXdvnqfs-OYlgoWCX_cjwElpvHDdZ9XE0ViKWGhBIcXa8J-eXYkNhWZcW056Yba1EwoayVL9VkKr1cIGwbLJcAPLSUn1NGMYvESGxo4R6AgVhimsm44CZn0aWL5bg2Ne53VQywYs9xyd9CcFnxJ7opTfSHdTSqE6cqWkC_TCIz196ll3r0aMQfaO5RuuYA6nctmQzhFxC9r1CNaIwbRYqJBE766rFVXXQq0heLBdHV6MP-xd35Jg_gOMv5sYcRwCGUbX-9SPeCZDbz71edTKh9A5f2P3yRrU6h41YuDEq_H3uquKNBBxehnbM0f7Tiz2C9emsPNYY8h063lwLBLj6O8giXAQTc5g0K-rY8lE-kfMBSdC-oluX-L3iX2V4-iaw-MYIOjqatEm7WIr0mozBF4IjLvAl9xWENkf_MrMZnbZ5q_FJaJ5ZJAJdEetgyC08tZgJVTUN6ks9Yp_pS0C5MHV-RhsGzvahXbSNEjU-bINz99DVrIsxXo_zT1gOeACzDzQ0OA=w800-h600-no)

**Power Supply:**

![](https://lh3.googleusercontent.com/MS2Le4paDxa0HZ7ci20AOiSfDLobb8iPRdnxbgo0oIp4Iba4LVlIEwPEvm0-sj2u82hCSosb0cS7GJZ7YrFQ3rjctBVUYCgRvjqXKHbWySbc12jiAE-xlmciQIJXnvCXm7SMK7AYrkDJcOf-2vdV1jLrUkIMMDaph6r-vXgUJCOoInkc5aEwWrfYdV68Tn4xB88IY0Y9w5jejbqJtdBxAUbmlnvSCw3cKh2UAmgyY3IqoDEU0kRq5wdRxv633kwVIYHL7XbTHx7-hZ59iYkJkcj74_KEqdkYm6mWgqPmAIeroTmyrx7lUVrTx0vcQBlEXXU3zQMBTngp_QcKbNSdP3sl_fNsRGyGGBwnQu_TePvNlRfVGCB7WVimb5RPR8L1G24wCaM5CUcAW-CJmbARTvZbG-rz8NGTop2HvrUwLe_A0jcs-zOdRfqtmASEqzV_URSHl-fEjHxxzAtKDba5sCsOUlPWU6v0pXsejaP-K5tXaF4jc1yBEox6PvV_8aesaseVwv-V8TnikSn6lu_zyT0UO4nU9LbxeJlQaKeJHbB73Z5HmFuQR8xltFhPaWytdkPf_Y_yilwYdOF72uC0gCAO2JSDkHBmmDJoiwNJlR541xsjrGBdarLTHwOx6evEa6PPOA2QrBGtvj2kYljDWwE6mwVdE0heGQ=w800-h600-no)
