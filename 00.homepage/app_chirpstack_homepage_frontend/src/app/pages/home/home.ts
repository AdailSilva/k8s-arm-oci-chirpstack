import { Component } from '@angular/core';
import { HomeHero } from './hero';
import { HomeNumbers } from './numbers';
import { HomeVersions } from './versions';
import { HomeComparison } from './comparison';
import { HomeLorawan } from './lorawan';
import { HomeEcosystem } from './ecosystem';
import { HomeFaq } from './faq';
import { HomeContact } from './contact';

@Component({
    selector: 'home-page',
    standalone: true,
    imports: [HomeHero, HomeNumbers, HomeVersions, HomeComparison, HomeLorawan, HomeEcosystem, HomeFaq, HomeContact],
    template: `
        <home-hero />
        <home-numbers />
        <home-versions />
        <home-comparison />
        <home-lorawan />
        <home-ecosystem />
        <home-faq />
        <home-contact />
    `
})
export class Home {}
