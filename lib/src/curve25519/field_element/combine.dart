void combine(List<int> h) {
  final c = List<int>.filled(10, 0, growable: false);

  /*
      |h0| <= (1.1*1.1*2^52*(1+19+19+19+19)+1.1*1.1*2^50*(38+38+38+38+38))
        i.e. |h0| <= 1.2*2^59; narrower ranges for h2, h4, h6, h8
      |h1| <= (1.1*1.1*2^51*(1+1+19+19+19+19+19+19+19+19))
        i.e. |h1| <= 1.5*2^58; narrower ranges for h3, h5, h7, h9
    */

  c[0] = (h[0] + (1 << 25)) >> 26;
  h[1] += c[0];
  h[0] -= c[0] << 26;
  c[4] = (h[4] + (1 << 25)) >> 26;
  h[5] += c[4];
  h[4] -= c[4] << 26;
  /* |h0| <= 2^25 */
  /* |h4| <= 2^25 */
  /* |h1| <= 1.51*2^58 */
  /* |h5| <= 1.51*2^58 */

  c[1] = (h[1] + (1 << 24)) >> 25;
  h[2] += c[1];
  h[1] -= c[1] << 25;
  c[5] = (h[5] + (1 << 24)) >> 25;
  h[6] += c[5];
  h[5] -= c[5] << 25;
  /* |h1| <= 2^24; from now on fits into int32 */
  /* |h5| <= 2^24; from now on fits into int32 */
  /* |h2| <= 1.21*2^59 */
  /* |h6| <= 1.21*2^59 */

  c[2] = (h[2] + (1 << 25)) >> 26;
  h[3] += c[2];
  h[2] -= c[2] << 26;
  c[6] = (h[6] + (1 << 25)) >> 26;
  h[7] += c[6];
  h[6] -= c[6] << 26;
  /* |h2| <= 2^25; from now on fits into int32 unchanged */
  /* |h6| <= 2^25; from now on fits into int32 unchanged */
  /* |h3| <= 1.51*2^58 */
  /* |h7| <= 1.51*2^58 */

  c[3] = (h[3] + (1 << 24)) >> 25;
  h[4] += c[3];
  h[3] -= c[3] << 25;
  c[7] = (h[7] + (1 << 24)) >> 25;
  h[8] += c[7];
  h[7] -= c[7] << 25;
  /* |h3| <= 2^24; from now on fits into int32 unchanged */
  /* |h7| <= 2^24; from now on fits into int32 unchanged */
  /* |h4| <= 1.52*2^33 */
  /* |h8| <= 1.52*2^33 */

  c[4] = (h[4] + (1 << 25)) >> 26;
  h[5] += c[4];
  h[4] -= c[4] << 26;
  c[8] = (h[8] + (1 << 25)) >> 26;
  h[9] += c[8];
  h[8] -= c[8] << 26;
  /* |h4| <= 2^25; from now on fits into int32 unchanged */
  /* |h8| <= 2^25; from now on fits into int32 unchanged */
  /* |h5| <= 1.01*2^24 */
  /* |h9| <= 1.51*2^58 */

  c[9] = (h[9] + (1 << 24)) >> 25;
  h[0] += c[9] * 19;
  h[9] -= c[9] << 25;
  /* |h9| <= 2^24; from now on fits into int32 unchanged */
  /* |h0| <= 1.8*2^37 */

  c[0] = (h[0] + (1 << 25)) >> 26;
  h[1] += c[0];
  h[0] -= c[0] << 26;
  /* |h0| <= 2^25; from now on fits into int32 unchanged */
  /* |h1| <= 1.01*2^24 */
}
